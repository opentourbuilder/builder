import '../db.dart';
import 'point.dart';

class WaypointId {
  const WaypointId({
    required this.tourId,
    required this.waypointId,
  });

  final Uuid tourId;
  final Uuid waypointId;

  @override
  int get hashCode => Object.hash(tourId, waypointId);

  @override
  operator ==(Object other) =>
      other is WaypointId &&
      other.tourId == tourId &&
      other.waypointId == waypointId;
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
  Future<DbWaypoint> createWaypoint(Uuid tourId, Waypoint data) async {
    var waypointId = Uuid.v4();

    // insert it with invalid order
    await db.insert(symWaypoint, {
      symId: waypointId.bytes,
      symTour: tourId.bytes,
      symOrder: null,
      symName: data.name,
      symDesc: data.desc,
      symLat: data.lat,
      symLng: data.lng,
      symNarrationPath: symNarrationPath,
      symRevision: currentRevision.bytes,
      symCreated: currentRevision.bytes,
    });

    requestEvent(WaypointsEventDescriptor(tourId: tourId));

    var id = WaypointId(tourId: tourId, waypointId: waypointId);

    var state = DbObjectState(id, data);
    dbObjects[id] = state;

    return DbWaypoint._(state);
  }

  Future<DbWaypoint?> waypoint(Uuid tourId, Uuid waypointId) async {
    return load<DbWaypoint, WaypointId, Waypoint>(
      id: WaypointId(tourId: tourId, waypointId: waypointId),
      load: () async {
        var rows = await instance.db.query(
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

  Future<void> deleteWaypoint(Uuid tourId, Uuid waypointId) async {
    dbObjects.remove(WaypointId(tourId: tourId, waypointId: waypointId));

    await db.delete(
      symWaypoint,
      where: "$symTour = ? AND $symId = ?",
      whereArgs: [tourId.bytes, waypointId.bytes],
    );

    requestEvent(WaypointsEventDescriptor(tourId: tourId));
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
    await instance.db.update(
      symWaypoint,
      {
        ...state.data._toRow(),
        symRevision: instance.currentRevision.bytes,
      },
      where: "$symTour = ? AND $symId = ?",
      whereArgs: [state.id.tourId.bytes, state.id.waypointId.bytes],
    );

    instance.requestEvent(WaypointsEventDescriptor(tourId: state.id.tourId));

    state.notify(object);
  }
}
