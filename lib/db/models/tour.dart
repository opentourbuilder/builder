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

  static Future<Tour?> load(EvresiDatabase db, Uuid tourId) async {
    var rows = await db.db.query(
      symTour,
      columns: [symName, symDesc],
      where: "$symId = ?",
      whereArgs: [tourId.bytes],
    );

    return rows.isEmpty ? null : Tour._fromRow(rows[0]);
  }

  Future<void> update(EvresiDatabase db, Uuid tourId) async {
    await db.db.update(
      symTour,
      {
        ..._toRow(),
        symRevision: db.currentRevision.bytes,
      },
      where: "$symId = ?",
      whereArgs: [tourId.bytes],
    );

    // in case the tour name was changed
    db.requestEvent(const ToursEventDescriptor());
  }

  Future<Uuid> create(EvresiDatabase db) async {
    var id = Uuid.v4();

    await db.db.insert(symTour, {
      symId: id.bytes,
      symName: name,
      symDesc: desc,
      symRevision: db.currentRevision.bytes,
      symCreated: db.currentRevision.bytes,
    });

    db.requestEvent(const ToursEventDescriptor());

    return id;
  }

  static Future<void> delete(EvresiDatabase db, Uuid tourId) async {
    await db.db.delete(
      symTour,
      where: "$symId = ?",
      whereArgs: [tourId],
    );
  }
}

class DbTourInfo extends DbObjectInfo<Uuid, Tour, DbTour> {
  DbTourInfo({required super.id, required super.data});

  static Future<DbTourInfo> create(Tour data) async {
    var id = await data.create(instance);

    return DbTourInfo(id: id, data: data);
  }

  static Future<DbTourInfo?> load(Uuid id) async {
    var data = await Tour.load(instance, id);

    return data != null ? DbTourInfo(id: id, data: data) : null;
  }

  @override
  Future<void> persist() async {
    data.update(instance, id);
  }
}

class DbTour extends DbObject<Uuid, Tour> {
  DbTour(DbTourInfo info) : super(info);

  String get name => info.target!.data.name;
  set name(String value) {
    info.target!.data.name = value;
    _changed();
  }

  String get desc => info.target!.data.desc;
  set desc(String value) {
    info.target!.data.desc = value;
    _changed();
  }

  void _changed() {
    info.target!.persist().then((_) => notify());
  }
}
