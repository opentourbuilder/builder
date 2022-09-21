import '../db.dart';

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

  static Future<Waypoint?> load(
      EvresiDatabase db, Uuid tourId, Uuid waypointId) async {
    var rows = await db.db.query(
      symWaypoint,
      columns: [symName, symDesc, symLat, symLng, symNarrationPath],
      where: "$symId = ?",
      whereArgs: [waypointId.bytes],
    );

    return rows.isEmpty ? null : Waypoint._fromRow(rows[0]);
  }

  Future<Uuid> create(EvresiDatabase db, Uuid tourId) async {
    var id = Uuid.v4();

    // insert it with invalid order
    await db.db.insert(symWaypoint, {
      symId: id.bytes,
      symTour: tourId.bytes,
      symOrder: null,
      symName: name,
      symDesc: desc,
      symLat: lat,
      symLng: lng,
      symNarrationPath: symNarrationPath,
      symRevision: db.currentRevision.bytes,
      symCreated: db.currentRevision.bytes,
    });

    db.requestEvent(WaypointsEventDescriptor(tourId: tourId));

    return id;
  }

  Future<void> update(EvresiDatabase db, Uuid tourId, Uuid waypointId) async {
    await db.db.update(
      symWaypoint,
      {
        ..._toRow(),
        symRevision: db.currentRevision.bytes,
      },
      where: "$symTour = ? AND $symId = ?",
      whereArgs: [tourId.bytes, waypointId.bytes],
    );

    db.requestEvent(WaypointsEventDescriptor(tourId: tourId));
  }

  static Future<void> delete(
      EvresiDatabase db, Uuid tourId, Uuid waypointId) async {
    await db.db.delete(
      symWaypoint,
      where: "$symTour = ? AND $symId = ?",
      whereArgs: [tourId.bytes, waypointId.bytes],
    );
  }
}

class DbWaypointInfo
    extends DbObjectInfo<FullWaypointId, Waypoint, DbWaypointInfo> {
  DbWaypointInfo({required super.id, required super.data});

  static Future<DbWaypointInfo> create(Uuid tourId, Waypoint data) async {
    var waypointId = await data.create(instance, tourId);
    var id = FullWaypointId(tourId: tourId, waypointId: waypointId);

    return DbWaypointInfo(id: id, data: data);
  }

  static Future<DbWaypointInfo?> load(FullWaypointId id) async {
    var data = await Waypoint.load(instance, id.tourId, id.waypointId);

    return data != null ? DbWaypointInfo(id: id, data: data) : null;
  }

  Future<void> persist() async {
    data.update(instance, id.tourId, id.waypointId);
  }
}

class DbWaypoint extends DbObject<FullWaypointId, Waypoint, DbWaypointInfo> {
  DbWaypoint(DbWaypointInfo info) : super(info);

  String? get name => info!.data.name;
  set name(String? value) {
    info!.data.name = value;
    _changed();
  }

  String? get desc => info!.data.desc;
  set desc(String? value) {
    info!.data.desc = value;
    _changed();
  }

  double get lat => info!.data.lat;
  set lat(double value) {
    info!.data.lat = value;
    _changed();
  }

  double get lng => info!.data.lng;
  set lng(double value) {
    info!.data.lng = value;
    _changed();
  }

  String? get narrationPath => info!.data.narrationPath;
  set narrationPath(String? value) {
    info!.data.narrationPath = value;
    _changed();
  }

  void _changed() {
    info!.persist().then((_) => notify());
  }
}
