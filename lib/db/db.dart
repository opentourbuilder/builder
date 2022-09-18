import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

import './db_object.dart';
import 'models/tour.dart';
import 'models/waypoint.dart';

export './db_object.dart';

late EvresiDatabase _db;

Future<void> initEvresiDatabase() async {
  /*var dir = await getApplicationSupportDirectory();
  dir.create(recursive: true);

  _db = EvresiDatabase();
  await _db.open(p.join(dir.path, 'main.db'));*/

  _db = EvresiDatabase();
  await _db.open(inMemoryDatabasePath);
}

EvresiDatabase get instance => _db;

class EvresiDatabase {
  late Database db;

  late Uuid currentRevision;

  final Map<dynamic, DbObjectInfo> dbObjects = {};

  final StreamController<Event> _events = StreamController.broadcast();
  Stream<Event> get events => _events.stream;

  Future<void> open(String path) async {
    db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(_sqlOnCreate);
        },
      ),
    );

    await _initCurrentRevision();
  }

  Future<void> close() async {
    await db.close();
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

  Future<Uuid> createTour(Tour data) async {
    var info = await DbTourInfo.create(data);
    dbObjects[info.id] = info;
    return info.id;
  }

  Future<DbTour?> tour(Uuid id) async {
    var info = dbObjects[id] as DbTourInfo?;
    if (!dbObjects.containsKey(id)) {
      info = await DbTourInfo.load(id);

      if (info != null) dbObjects[id] = info;
    }

    if (info != null) {
      return DbTour(info);
    } else {
      return null;
    }
  }

  Future<Uuid> createWaypoint(Uuid tourId, Waypoint data) async {
    var info = await DbWaypointInfo.create(tourId, data);
    dbObjects[info.id] = info;
    return info.id.waypointId;
  }

  Future<DbWaypoint?> waypoint(Uuid tourId, Uuid waypointId) async {
    var id = FullWaypointId(tourId: tourId, waypointId: waypointId);
    DbWaypointInfo? info;
    if (!dbObjects.containsKey(id)) {
      info = await DbWaypointInfo.load(id);

      if (info != null) dbObjects[id] = info;
    } else {
      info = dbObjects[id] as DbWaypointInfo;
    }

    if (info != null) {
      return DbWaypoint(info);
    } else {
      return null;
    }
  }

  Future<void> _initCurrentRevision() async {
    var uncommittedRevisions = (await db.query(
      symRevision,
      columns: [symId],
      where: "$symCommitted = 0",
    ))
        .map((row) => Uuid(row[symId]! as Uint8List))
        .toList();

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
  }
}

class Poi {
  Poi({
    required this.name,
    required this.desc,
    required this.lat,
    required this.lng,
  });

  Poi._fromRow(Map<String, Object?> row)
      : name = row[symName]! as String,
        desc = row[symDesc]! as String,
        lat = row[symLat]! as double,
        lng = row[symLng]! as double;

  Map<String, Object?> _toRow() => {
        symName: name,
        symDesc: desc,
        symLat: lat,
        symLng: lng,
      };

  String name;
  String desc;
  double lat;
  double lng;
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

  Future<T> _observe(EvresiDatabase db);
}

class ToursEventDescriptor extends EventDescriptor<List<TourSummary>> {
  const ToursEventDescriptor();

  @override
  Future<List<TourSummary>> _observe(EvresiDatabase db) async {
    var rows = await db.db.query(
      symTour,
      columns: [symId, symName],
      orderBy: symName,
    );

    return rows.map(TourSummary._fromRow).toList();
  }

  @override
  bool operator ==(Object other) => other is ToursEventDescriptor;

  @override
  int get hashCode => runtimeType.hashCode + 1;
}

class WaypointsEventDescriptor extends EventDescriptor<List<PointSummary>> {
  const WaypointsEventDescriptor({required this.tourId});

  final Uuid tourId;

  @override
  Future<List<PointSummary>> _observe(EvresiDatabase db) async {
    var rows = await db.db.query(
      symWaypoint,
      columns: [symId, symOrder, symLat, symLng, symName],
      where: "$symTour = ?",
      whereArgs: [tourId.bytes],
      orderBy: symOrder,
    );

    return rows.map(PointSummary._fromRow).toList();
  }

  @override
  bool operator ==(Object other) =>
      other is WaypointsEventDescriptor && tourId == other.tourId;

  @override
  int get hashCode => tourId.hashCode;
}

class PoisEventDescriptor extends EventDescriptor<List<PointSummary>> {
  const PoisEventDescriptor();

  @override
  Future<List<PointSummary>> _observe(EvresiDatabase db) async {
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

/// A short summary of a tour.
class TourSummary {
  const TourSummary({
    required this.id,
    required this.name,
  });

  TourSummary._fromRow(Map<String, Object?> row)
      : id = Uuid(row[symId]! as Uint8List),
        name = row[symName]! as String;

  final Uuid id;
  final String name;
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

const _sqlOnCreate = """
  CREATE TABLE IF NOT EXISTS $symGallery (
     $symItem BLOB NOT NULL,
     $symPath TEXT NOT NULL,
     $symOrder INTEGER NOT NULL,
    PRIMARY KEY ($symItem)
  );

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

  CREATE TABLE IF NOT EXISTS $symRevision (
     $symId BLOB NOT NULL,
     $symTimestamp INTEGER NOT NULL,
     $symUser TEXT NOT NULL,
     $symCommitted INTEGER NOT NULL,
    PRIMARY KEY ($symId)
  );

  CREATE TABLE IF NOT EXISTS $symTour (
     $symId BLOB NOT NULL,
     $symName TEXT NOT NULL,
     $symDesc TEXT NOT NULL,
     $symRevision BLOB NOT NULL,
     $symCreated BLOB NOT NULL,
    PRIMARY KEY ($symId),
    FOREIGN KEY ($symRevision) REFERENCES  $symRevision ($symId),
    FOREIGN KEY ($symCreated) REFERENCES  $symRevision ($symId)
  );

  CREATE TABLE IF NOT EXISTS $symWaypoint (
     $symId BLOB NOT NULL,
     $symTour BLOB NOT NULL,
     $symOrder INTEGER,
     $symName TEXT,
     $symDesc TEXT,
     $symLat REAL NOT NULL,
     $symLng REAL NOT NULL,
     $symNarrationPath TEXT,
     $symRevision BLOB NOT NULL,
     $symCreated BLOB NOT NULL,
    PRIMARY KEY ($symId),
    FOREIGN KEY ($symTour) REFERENCES  $symTour ($symId),
    FOREIGN KEY ($symRevision) REFERENCES  $symRevision ($symId),
    FOREIGN KEY ($symCreated) REFERENCES  $symRevision ($symId)
  );
""";
