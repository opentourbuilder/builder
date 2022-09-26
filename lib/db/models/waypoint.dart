import 'package:flutter/foundation.dart';

import '../db.dart';
import 'point.dart';

class WaypointId {
  const WaypointId(this.waypointId);

  final Uuid waypointId;

  @override
  int get hashCode => waypointId.hashCode;

  @override
  operator ==(Object other) =>
      other is WaypointId && other.waypointId == waypointId;
}

class WaypointWithId {
  const WaypointWithId({required this.id, required this.waypoint});

  final Uuid id;
  final Waypoint waypoint;
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
      : name = row[symName] as String?,
        desc = row[symDesc] as String?,
        lat = row[symLat]! as double,
        lng = row[symLng]! as double,
        narrationPath = row[symNarrationPath] as String?;

  Map<String, Object?> _toRow() => {
        symName: name,
        symDesc: desc,
        symLat: lat,
        symLng: lng,
        symNarrationPath: narrationPath,
      };

  String? name;
  String? desc;
  double lat;
  double lng;
  String? narrationPath;
}

mixin EvresiDatabaseWaypointMixin on EvresiDatabaseBase {
  Future<DbWaypoint> createWaypoint(Waypoint data) async {
    if (type != EvresiDatabaseType.tour) {
      throw Exception(
          "Attempted to use Tour-only method in non-Tour database.");
    }

    var waypointId = Uuid.v4();

    // insert it with invalid order
    await db!.insert(symWaypoint, {
      symId: waypointId.bytes,
      symOrder: null,
      symName: data.name,
      symDesc: data.desc,
      symLat: data.lat,
      symLng: data.lng,
      symNarrationPath: symNarrationPath,
      symRevision: currentRevision.bytes,
      symCreated: currentRevision.bytes,
    });

    requestEvent(const WaypointsEventDescriptor());

    var id = WaypointId(waypointId);

    var state = DbObjectState(id, data);
    dbObjects[id] = state;

    return DbWaypoint._(state);
  }

  Future<DbWaypoint?> waypoint(Uuid waypointId) async {
    if (type != EvresiDatabaseType.tour) {
      throw Exception(
          "Attempted to use Tour-only method in non-Tour database.");
    }

    return load<DbWaypoint, WaypointId, Waypoint>(
      id: WaypointId(waypointId),
      load: () async {
        var rows = await db!.query(
          symWaypoint,
          columns: [symName, symDesc, symLat, symLng, symNarrationPath],
          where: "$symId = ?",
          whereArgs: [waypointId.bytes],
        );
        return rows.isEmpty ? null : Waypoint._fromRow(rows[0]);
      },
      createObject: (state) => DbWaypoint._(state),
    );
  }

  Future<void> deleteWaypoint(Uuid waypointId) async {
    if (type != EvresiDatabaseType.tour) {
      throw Exception(
          "Attempted to use Tour-only method in non-Tour database.");
    }

    var obj = dbObjects.remove(WaypointId(waypointId));
    obj?.markDeleted();
    obj?.notify(null);

    await db!.delete(
      symWaypoint,
      where: "$symId = ?",
      whereArgs: [waypointId.bytes],
    );

    requestEvent(const WaypointsEventDescriptor());
  }

  Future<List<WaypointWithId>> listWaypoints() async {
    if (type != EvresiDatabaseType.tour) {
      throw Exception(
          "Attempted to use Tour-only method in non-Tour database.");
    }

    return (await db!.query(
      symWaypoint,
      columns: [symId, symName, symDesc, symLat, symLng, symNarrationPath],
    ))
        .map((row) => WaypointWithId(
              id: Uuid(row[symId]! as Uint8List),
              waypoint: Waypoint._fromRow(row),
            ))
        .toList();
  }
}

class DbWaypoint extends DbObject<DbWaypointAccessor, WaypointId, Waypoint> {
  DbWaypoint._(DbObjectState<WaypointId, Waypoint> state)
      : super((self) => DbWaypointAccessor(self), state);
}

class DbWaypointAccessor implements DbPointAccessor {
  DbWaypointAccessor(this.object);

  final DbObject<DbWaypointAccessor, WaypointId, Waypoint> object;
  late final DbObjectState<WaypointId, Waypoint> state = object.state!;

  String? get name => state.data.name;
  set name(String? value) {
    state.data.name = value;
    _changed();
  }

  String? get desc => state.data.desc;
  set desc(String? value) {
    state.data.desc = value;
    _changed();
  }

  @override
  double get lat => state.data.lat;
  @override
  set lat(double value) {
    state.data.lat = value;
    _changed();
  }

  @override
  double get lng => state.data.lng;
  @override
  set lng(double value) {
    state.data.lng = value;
    _changed();
  }

  String? get narrationPath => state.data.narrationPath;
  set narrationPath(String? value) {
    state.data.narrationPath = value;
    _changed();
  }

  void _changed() async {
    await instance.db!.update(
      symWaypoint,
      {
        ...state.data._toRow(),
        symRevision: instance.currentRevision.bytes,
      },
      where: "$symId = ?",
      whereArgs: [state.id.waypointId.bytes],
    );

    instance.requestEvent(const WaypointsEventDescriptor());

    state.notify(object);
  }
}
