import '../db.dart';

class Tour {
  Tour({
    required this.name,
    required this.desc,
  });

  Tour._fromRow(Map<String, Object?> row)
      : name = row[symName]! as String,
        desc = row[symDesc]! as String;

  Map<String, Object?> _toRow() => {
        symName: name,
        symDesc: desc,
      };

  String name;
  String desc;
}

mixin EvresiDatabaseTourMixin on EvresiDatabaseBase {
  Future<DbTour> createTour(Tour data) async {
    var id = Uuid.v4();

    await instance.db.insert(symTour, {
      symId: id.bytes,
      symName: data.name,
      symDesc: data.desc,
      symRevision: instance.currentRevision.bytes,
      symCreated: instance.currentRevision.bytes,
    });

    instance.requestEvent(const ToursEventDescriptor());

    var state = DbObjectState(id, data);
    dbObjects[id] = state;

    return DbTour._(state);
  }

  Future<DbTour?> tour(Uuid id) async {
    return load<DbTour, Uuid, Tour>(
      id: id,
      load: () async {
        var rows = await instance.db.query(
          symTour,
          columns: [symName, symDesc],
          where: "$symId = ?",
          whereArgs: [id.bytes],
        );
        return rows.isEmpty ? null : Tour._fromRow(rows[0]);
      },
      createObject: (state) => DbTour._(state),
    );
  }

  Future<void> deleteTour(Uuid tourId) async {
    dbObjects.remove(tourId);

    await instance.db.delete(
      symTour,
      where: "$symId = ?",
      whereArgs: [tourId],
    );

    requestEvent(const ToursEventDescriptor());
  }
}

class DbTour extends DbObject<DbTourAccessor, Uuid, Tour> {
  DbTour._(DbObjectState<Uuid, Tour> state)
      : super((self) => DbTourAccessor(self), state);
}

class DbTourAccessor {
  DbTourAccessor(this.object);

  final DbObject<DbTourAccessor, Uuid, Tour> object;
  late final DbObjectState<Uuid, Tour> state = object.state!;

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

  void _changed() async {
    await instance.db.update(
      symTour,
      {
        ...state.data._toRow(),
        symRevision: instance.currentRevision.bytes,
      },
      where: "$symId = ?",
      whereArgs: [state.id.bytes],
    );

    // in case the tour name was changed
    instance.requestEvent(const ToursEventDescriptor());

    state.notify(object);
  }
}
