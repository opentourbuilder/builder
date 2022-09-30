import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

import './db_object.dart';
import 'models/gallery.dart';
import 'models/poi.dart';
import 'models/tour.dart';
import 'models/waypoint.dart';

export './db_object.dart';

enum EvresiDatabaseType {
  tour,
  poiSet,
}

class EvresiDatabase extends EvresiDatabaseBase
    with
        EvresiDatabaseWaypointMixin,
        EvresiDatabaseTourMixin,
        EvresiDatabaseGalleryMixin,
        EvresiDatabasePoiMixin {
  EvresiDatabase._(super.db, super.type, super.currentRevision) : super._();

  static Future<EvresiDatabase> open(
      String path, EvresiDatabaseType type) async {
    var db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(type == EvresiDatabaseType.tour
              ? _tourSqlOnCreate
              : _poiSetSqlOnCreate);
        },
      ),
    );

    var uncommittedRevisions = (await db.query(
      symRevision,
      columns: [symId],
      where: "$symCommitted = 0",
    ))
        .map((row) => Uuid(row[symId]! as Uint8List))
        .toList();

    Uuid currentRevision;
    if (uncommittedRevisions.isEmpty) {
      // create new revision if there is no uncommitted one
      var id = Uuid.v4();

      await db.insert(symRevision, {
        symId: id.bytes,
        symTimestamp: DateTime.now().millisecondsSinceEpoch,
        symUser: "TODO", // TODO
        symCommitted: 0,
      });

      currentRevision = id;
    } else {
      currentRevision = uncommittedRevisions[0];
    }

    return EvresiDatabase._(db, type, currentRevision);
  }
}

class EvresiDatabaseBase {
  final EvresiDatabaseType type;
  Uuid currentRevision;
  Database? _db;
  Database get db => _db!; // _db should only be null if the DB was closed

  @protected
  final Map<dynamic, DbObjectState> dbObjects = {};

  final StreamController<Event> _events = StreamController.broadcast();
  Stream<Event> get events => _events.stream;

  EvresiDatabaseBase._(this._db, this.type, this.currentRevision);

  Future<void> close() async {
    var temp = db;
    _db = null;
    await temp.close();
  }

  // Commits the current revision of the database.
  Future<void> commit() async {}

  /// Requests that an event matching the given descriptor be sent on [events].
  void requestEvent(EventDescriptor desc) async {
    _events.add(Event._(
      desc: desc,
      value: await desc._observe(this),
    ));
  }

  @protected
  Future<DbObj?> load<DbObj, Id, Data>({
    required Id id,
    required Future<Data?> Function() load,
    required DbObj Function(DbObjectState<Id, Data>) createObject,
  }) async {
    if (dbObjects.containsKey(id)) {
      return createObject(dbObjects[id]! as DbObjectState<Id, Data>);
    } else {
      var data = await load();

      if (data != null) {
        var state = DbObjectState(this, id, data);
        dbObjects[id] = state;
        return createObject(state);
      } else {
        return null;
      }
    }
  }
}

class Event<D extends EventDescriptor<T>, T> {
  Event._({
    required this.desc,
    required this.value,
  });

  final D desc;
  final T value;
}

abstract class EventDescriptor<T> {
  const EventDescriptor();

  Future<T> _observe(EvresiDatabaseBase db);
}

class WaypointsEventDescriptor extends EventDescriptor<List<PointSummary>> {
  const WaypointsEventDescriptor();

  @override
  Future<List<PointSummary>> _observe(EvresiDatabaseBase db) async {
    var rows = await db.db.query(
      symWaypoint,
      columns: [symId, symOrder, symLat, symLng, symName],
      orderBy: symOrder,
    );

    return rows.map(PointSummary._fromRow).toList();
  }

  @override
  bool operator ==(Object other) => other is WaypointsEventDescriptor;

  @override
  int get hashCode => runtimeType.hashCode;
}

class PoisEventDescriptor extends EventDescriptor<List<PointSummary>> {
  const PoisEventDescriptor();

  @override
  Future<List<PointSummary>> _observe(EvresiDatabaseBase db) async {
    var rows = await db.db.query(
      symPoi,
      columns: [symId, symLat, symLng, symName],
      orderBy: symName,
    );

    return rows.map(PointSummary._fromRow).toList();
  }

  @override
  bool operator ==(Object other) => other is PoisEventDescriptor;

  @override
  int get hashCode => runtimeType.hashCode + 1;
}

class PointSummary {
  const PointSummary({
    required this.id,
    required this.lat,
    required this.lng,
    required this.name,
  });

  PointSummary._fromRow(Map<String, Object?> row)
      : id = Uuid(row[symId]! as Uint8List),
        lat = row[symLat]! as double,
        lng = row[symLng]! as double,
        name = row[symName] as String?;

  final Uuid id;
  final double lat;
  final double lng;
  final String? name;
}

class Uuid {
  /// Creates a UUID from 16 bytes.
  const Uuid(this.bytes) : assert(bytes.length == 16);

  // this could probably be faster if we generated it ourselves.
  /// Creates a random UUID (version 4).
  Uuid.v4() : bytes = const uuid_lib.Uuid().v4obj().toBytes();

  static final zero = Uuid(
      Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));

  final Uint8List bytes;

  @override
  bool operator ==(Object other) =>
      other is Uuid && listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);

  String toHex() {
    String bitsToHexDigit(int bits) {
      return "0123456789abcdef"[bits];
    }

    String byteToHex(int byte) {
      return bitsToHexDigit((byte & 0xF0) >> 4) + bitsToHexDigit(byte & 0xF);
    }

    var hex = "";
    for (final byte in bytes) {
      hex += byteToHex(byte);
    }

    return hex;
  }
}

// All of the column and table names, so we can rely on the IDE to prevent typos.
const symItem = 'item';
const symPath = 'path';
const symOrder = '_order'; // get around keyword
const symId = 'id';
const symName = 'name';
const symDesc = 'desc';
const symLat = 'lat';
const symLng = 'lng';
const symRevision = 'revision';
const symCreated = 'created';
const symTimestamp = 'timestamp';
const symUser = 'user';
const symCommitted = 'committed';
const symNarrationPath = 'narration_path';
const symTour = 'tour';
const symWaypoint = 'waypoint';
const symPoi = 'poi';
const symGallery = 'gallery';

const _commonSqlOnCreate = """
  CREATE TABLE IF NOT EXISTS $symGallery (
     $symItem BLOB NOT NULL,
     $symPath TEXT NOT NULL,
     $symOrder INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS $symRevision (
     $symId BLOB NOT NULL,
     $symTimestamp INTEGER NOT NULL,
     $symUser TEXT NOT NULL,
     $symCommitted INTEGER NOT NULL,
    PRIMARY KEY ($symId)
  );
""";

const _tourSqlOnCreate = """
  $_commonSqlOnCreate

  CREATE TABLE IF NOT EXISTS $symTour (
     $symName TEXT NOT NULL,
     $symDesc TEXT NOT NULL,
     $symRevision BLOB NOT NULL,
     $symCreated BLOB NOT NULL,
    FOREIGN KEY ($symRevision) REFERENCES  $symRevision ($symId),
    FOREIGN KEY ($symCreated) REFERENCES  $symRevision ($symId)
  );

  CREATE TABLE IF NOT EXISTS $symWaypoint (
     $symId BLOB NOT NULL,
     $symOrder INTEGER,
     $symName TEXT,
     $symDesc TEXT,
     $symLat REAL NOT NULL,
     $symLng REAL NOT NULL,
     $symNarrationPath TEXT,
     $symRevision BLOB NOT NULL,
     $symCreated BLOB NOT NULL,
    PRIMARY KEY ($symId),
    FOREIGN KEY ($symRevision) REFERENCES  $symRevision ($symId),
    FOREIGN KEY ($symCreated) REFERENCES  $symRevision ($symId)
  );
""";

const _poiSetSqlOnCreate = """
  $_commonSqlOnCreate

  CREATE TABLE IF NOT EXISTS $symPoi (
     $symId BLOB NOT NULL,
     $symName TEXT NOT NULL,
     $symDesc TEXT,
     $symLat REAL NOT NULL,
     $symLng REAL NOT NULL,
     $symRevision BLOB NOT NULL,
     $symCreated BLOB NOT NULL,
    FOREIGN KEY ($symRevision) REFERENCES  $symRevision ($symId),
    FOREIGN KEY ($symCreated) REFERENCES  $symRevision ($symId)
  );
""";
