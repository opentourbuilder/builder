import '../db.dart';
import 'point.dart';

class PoiId {
  const PoiId(this.poiId);

  final Uuid poiId;

  @override
  int get hashCode => poiId.hashCode;

  @override
  operator ==(Object other) => other is PoiId && other.poiId == poiId;
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

mixin EvresiDatabasePoiMixin on EvresiDatabaseBase {
  Future<DbPoi> createPoi(Poi data) async {
    var poiId = Uuid.v4();

    await db.insert(symPoi, {
      symId: poiId.bytes,
      symName: data.name,
      symDesc: data.desc,
      symLat: data.lat,
      symLng: data.lng,
      symRevision: currentRevision.bytes,
      symCreated: currentRevision.bytes,
    });

    requestEvent(const PoisEventDescriptor());

    var id = PoiId(poiId);

    var state = DbObjectState(id, data);
    dbObjects[id] = state;

    return DbPoi._(state);
  }

  Future<DbPoi?> poi(Uuid poiId) async {
    return load<DbPoi, PoiId, Poi>(
      id: PoiId(poiId),
      load: () async {
        var rows = await instance.db.query(
          symPoi,
          columns: [symName, symDesc, symLat, symLng],
          where: "$symId = ?",
          whereArgs: [poiId.bytes],
        );
        return rows.isEmpty ? null : Poi._fromRow(rows[0]);
      },
      createObject: (state) => DbPoi._(state),
    );
  }

  Future<void> deletePoi(Uuid poiId) async {
    dbObjects.remove(PoiId(poiId));

    await db.delete(
      symPoi,
      where: "$symId = ?",
      whereArgs: [poiId.bytes],
    );

    requestEvent(const PoisEventDescriptor());
  }
}

class DbPoi extends DbObject<DbPoiAccessor, PoiId, Poi> {
  DbPoi._(DbObjectState<PoiId, Poi> state)
      : super((self) => DbPoiAccessor(self), state);
}

class DbPoiAccessor implements DbPointAccessor {
  DbPoiAccessor(this.object);

  final DbObject<DbPoiAccessor, PoiId, Poi> object;
  late final DbObjectState<PoiId, Poi> state = object.state!;

  String get name => state.data.name;
  set name(String value) {
    state.data.name = value;
    _changed();
  }

  String get desc => state.data.desc;
  set desc(String value) {
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

  void _changed() async {
    await instance.db.update(
      symPoi,
      {
        ...state.data._toRow(),
        symRevision: instance.currentRevision.bytes,
      },
      where: "$symId = ?",
      whereArgs: [state.id.poiId.bytes],
    );

    instance.requestEvent(const PoisEventDescriptor());

    state.notify(object);
  }
}