import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

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
  late Database _db;

  late Uuid _currentRevision;

  final StreamController<Event> _events = StreamController.broadcast();
  Stream<Event> get events => _events.stream;

  Future<void> open(String path) async {
    _db = await databaseFactoryFfi.openDatabase(
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
    await _db.close();
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

  /// Gets the tour with the given `tourId` from the database.
  Future<Tour?> loadTour(Uuid tourId) async {
    var rows = await _db.query(
      _symTour,
      columns: [_symName, _symDesc],
      where: "$_symId = ?",
      whereArgs: [tourId.bytes],
    );

    return rows.isEmpty ? null : Tour._fromRow(rows[0]);
  }

  Future<void> updateTour(Uuid tourId, Tour tour) async {
    await _db.update(
      _symTour,
      {
        ...tour._toRow(),
        _symRevision: _currentRevision.bytes,
      },
      where: "$_symId = ?",
      whereArgs: [tourId.bytes],
    );

    // in case the tour name was changed
    requestEvent(const ToursEventDescriptor());
  }

  Future<Uuid> createTour(Tour tour) async {
    var id = Uuid.v4();

    await _db.insert(_symTour, {
      _symId: id.bytes,
      _symName: tour.name,
      _symDesc: tour.desc,
      _symRevision: _currentRevision.bytes,
      _symCreated: _currentRevision.bytes,
    });

    requestEvent(const ToursEventDescriptor());

    return id;
  }

  Future<Waypoint?> loadWaypoint(Uuid waypointId) async {
    var rows = await _db.query(
      _symWaypoint,
      columns: [_symName, _symDesc, _symLat, _symLng, _symNarrationPath],
      where: "$_symId = ?",
      whereArgs: [waypointId.bytes],
    );

    return rows.isEmpty ? null : Waypoint._fromRow(rows[0]);
  }

  Future<void> updateWaypoint(
    Uuid tourId,
    Uuid waypointId,
    Waypoint waypoint,
  ) async {
    await _db.update(
      _symWaypoint,
      {
        ...waypoint._toRow(),
        _symRevision: _currentRevision.bytes,
      },
      where: "$_symTour = ? AND $_symId = ?",
      whereArgs: [tourId.bytes, waypointId.bytes],
    );

    requestEvent(WaypointsEventDescriptor(tourId: tourId));
  }

  Future<Uuid> createWaypoint(Uuid tourId, Waypoint waypoint) async {
    var id = Uuid.v4();

    // insert it with invalid order
    await _db.insert(_symWaypoint, {
      _symId: id.bytes,
      _symTour: tourId.bytes,
      _symOrder: null,
      _symName: waypoint.name,
      _symDesc: waypoint.desc,
      _symLat: waypoint.lat,
      _symLng: waypoint.lng,
      _symNarrationPath: _symNarrationPath,
      _symRevision: _currentRevision.bytes,
      _symCreated: _currentRevision.bytes,
    });

    requestEvent(WaypointsEventDescriptor(tourId: tourId));

    return id;
  }

  Future<void> updateWaypointOrdering(
    Uuid tourId,
    Iterable<Uuid> ordering,
  ) async {
    // first, let's get the list of all waypoints
    var allWaypoints = (await _db.query(
      _symWaypoint,
      columns: [_symId],
      where: "$_symTour = ?",
      whereArgs: [tourId.bytes],
    ))
        .map((row) => Uuid(row[_symId]! as Uint8List))
        .toList();

    var batch = _db.batch();

    // now, let's update the ordering
    int order = 0;
    for (var waypointId in ordering) {
      allWaypoints.remove(waypointId);
      batch.update(
        _symWaypoint,
        {
          _symOrder: order,
        },
        where: "$_symId = ?",
        whereArgs: [waypointId.bytes],
      );
      order++;
    }

    // set order to null for non-included waypoints (allWaypoints had each
    // waypoint that was included in the ordering removed from it)
    for (var waypointId in allWaypoints) {
      batch.update(
        _symWaypoint,
        {
          _symOrder: null,
        },
        where: "$_symId = ?",
        whereArgs: [waypointId.bytes],
      );
    }

    // now, update the tour's revision
    batch.update(
      _symTour,
      {
        _symRevision: _currentRevision.bytes,
      },
      where: "$_symId = ?",
      whereArgs: [tourId.bytes],
    );

    // execute the batch
    await batch.commit(noResult: true);

    // finally, request the event
    requestEvent(WaypointsEventDescriptor(tourId: tourId));
  }

  Future<Poi?> loadPoi(Uuid poiId) async {
    var rows = await _db.query(
      _symPoi,
      columns: [_symName, _symDesc, _symLat, _symLng],
      where: "$_symId = ?",
      whereArgs: [poiId.bytes],
    );

    return rows.isEmpty ? null : Poi._fromRow(rows[0]);
  }

  Future<void> updatePoi(Uuid poiId, Poi poi) async {
    await _db.update(
      _symPoi,
      {
        ...poi._toRow(),
        _symRevision: _currentRevision.bytes,
      },
      where: "$_symId = ?",
      whereArgs: [poiId.bytes],
    );

    requestEvent(const PoisEventDescriptor());
  }

  Future<Uuid> createPoi(Poi poi) async {
    var id = Uuid.v4();

    await _db.insert(_symPoi, {
      _symId: id.bytes,
      _symName: poi.name,
      _symDesc: poi.desc,
      _symLat: poi.lat,
      _symLng: poi.lng,
      _symRevision: _currentRevision.bytes,
      _symCreated: _currentRevision.bytes,
    });

    requestEvent(const PoisEventDescriptor());

    return id;
  }

  Future<void> _initCurrentRevision() async {
    var uncommittedRevisions = (await _db.query(
      _symRevision,
      columns: [_symId],
      where: "$_symCommitted = 0",
    ))
        .map((row) => Uuid(row[_symId]! as Uint8List))
        .toList();

    if (uncommittedRevisions.isEmpty) {
      // create new revision if there is no uncommitted one
      var id = Uuid.v4();

      await _db.insert(_symRevision, {
        _symId: id.bytes,
        _symTimestamp: DateTime.now().millisecondsSinceEpoch,
        _symUser: "TODO", // TODO
        _symCommitted: 0,
      });

      _currentRevision = id;
    } else {
      _currentRevision = uncommittedRevisions[0];
    }
  }
}

class Tour {
  Tour({
    required this.name,
    required this.desc,
  });

  Tour._fromRow(Map<String, Object?> row)
      : name = row[_symName]! as String,
        desc = row[_symDesc]! as String;

  Map<String, Object?> _toRow() => {
        _symName: name,
        _symDesc: desc,
      };

  String name;
  String desc;
}

class Waypoint {
  Waypoint({
    required this.name,
    required this.desc,
    required this.lat,
    required this.lng,
    required this.narrationPath,
  });

  Waypoint._fromRow(Map<String, Object?> row)
      : name = row[_symName] as String?,
        desc = row[_symDesc] as String?,
        lat = row[_symLat]! as double,
        lng = row[_symLng]! as double,
        narrationPath = row[_symNarrationPath] as String?;

  Map<String, Object?> _toRow() => {
        _symName: name,
        _symDesc: desc,
        _symLat: lat,
        _symLng: lng,
        _symNarrationPath: narrationPath,
      };

  String? name;
  String? desc;
  double lat;
  double lng;
  String? narrationPath;
}

class Poi {
  Poi({
    required this.name,
    required this.desc,
    required this.lat,
    required this.lng,
  });

  Poi._fromRow(Map<String, Object?> row)
      : name = row[_symName]! as String,
        desc = row[_symDesc]! as String,
        lat = row[_symLat]! as double,
        lng = row[_symLng]! as double;

  Map<String, Object?> _toRow() => {
        _symName: name,
        _symDesc: desc,
        _symLat: lat,
        _symLng: lng,
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
    var rows = await db._db.query(
      _symTour,
      columns: [_symId, _symName],
      orderBy: _symName,
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
    var rows = await db._db.query(
      _symWaypoint,
      columns: [_symId, _symOrder, _symLat, _symLng, _symName],
      where: "$_symTour = ?",
      whereArgs: [tourId.bytes],
      orderBy: _symOrder,
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
    var rows = await db._db.query(
      _symPoi,
      columns: [_symId, _symLat, _symLng, _symName],
      orderBy: _symName,
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
      : id = Uuid(row[_symId]! as Uint8List),
        name = row[_symName]! as String;

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
      : id = Uuid(row[_symId]! as Uint8List),
        lat = row[_symLat]! as double,
        lng = row[_symLng]! as double,
        name = row[_symName] as String?;

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
  int get hashCode => hashList(bytes);

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
const _symItem = 'item';
const _symPath = 'path';
const _symOrder = '_order'; // get around keyword
const _symId = 'id';
const _symName = 'name';
const _symDesc = 'desc';
const _symLat = 'lat';
const _symLng = 'lng';
const _symRevision = 'revision';
const _symCreated = 'created';
const _symTimestamp = 'timestamp';
const _symUser = 'user';
const _symCommitted = 'committed';
const _symNarrationPath = 'narration_path';
const _symTour = 'tour';
const _symWaypoint = 'waypoint';
const _symPoi = 'poi';
const _symGallery = 'gallery';

const _sqlOnCreate = """
  CREATE TABLE IF NOT EXISTS $_symGallery (
     $_symItem BLOB NOT NULL,
     $_symPath TEXT NOT NULL,
     $_symOrder INTEGER NOT NULL,
    PRIMARY KEY ($_symItem)
  );

  CREATE TABLE IF NOT EXISTS $_symPoi (
     $_symId BLOB NOT NULL,
     $_symName TEXT NOT NULL,
     $_symDesc TEXT,
     $_symLat REAL NOT NULL,
     $_symLng REAL NOT NULL,
     $_symRevision BLOB NOT NULL,
     $_symCreated BLOB NOT NULL,
    FOREIGN KEY ($_symRevision) REFERENCES  $_symRevision ($_symId),
    FOREIGN KEY ($_symCreated) REFERENCES  $_symRevision ($_symId)
  );

  CREATE TABLE IF NOT EXISTS $_symRevision (
     $_symId BLOB NOT NULL,
     $_symTimestamp INTEGER NOT NULL,
     $_symUser TEXT NOT NULL,
     $_symCommitted INTEGER NOT NULL,
    PRIMARY KEY ($_symId)
  );

  CREATE TABLE IF NOT EXISTS $_symTour (
     $_symId BLOB NOT NULL,
     $_symName TEXT NOT NULL,
     $_symDesc TEXT NOT NULL,
     $_symRevision BLOB NOT NULL,
     $_symCreated BLOB NOT NULL,
    PRIMARY KEY ($_symId),
    FOREIGN KEY ($_symRevision) REFERENCES  $_symRevision ($_symId),
    FOREIGN KEY ($_symCreated) REFERENCES  $_symRevision ($_symId)
  );

  CREATE TABLE IF NOT EXISTS $_symWaypoint (
     $_symId BLOB NOT NULL,
     $_symTour BLOB NOT NULL,
     $_symOrder INTEGER,
     $_symName TEXT,
     $_symDesc TEXT,
     $_symLat REAL NOT NULL,
     $_symLng REAL NOT NULL,
     $_symNarrationPath TEXT,
     $_symRevision BLOB NOT NULL,
     $_symCreated BLOB NOT NULL,
    PRIMARY KEY ($_symId),
    FOREIGN KEY ($_symTour) REFERENCES  $_symTour ($_symId),
    FOREIGN KEY ($_symRevision) REFERENCES  $_symRevision ($_symId),
    FOREIGN KEY ($_symCreated) REFERENCES  $_symRevision ($_symId)
  );
""";
