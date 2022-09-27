import '../db.dart';

/// An ID that is equal to all other instances of the same type.
class TourId {
  const TourId();

  @override
  operator ==(Object other) => other is TourId;

  @override
  int get hashCode => runtimeType.hashCode;
}

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
  static final _blankTour = Tour(name: "Untitled", desc: "");

  Future<DbTour?> tour() async {
    if (type != EvresiDatabaseType.tour) {
      throw Exception(
          "Attempted to use Tour-only method in non-Tour database.");
    }

    return load<DbTour, TourId, Tour>(
      id: const TourId(),
      load: () async {
        var rows = await db!.query(
          symTour,
          columns: [symName, symDesc],
        );

        if (rows.isEmpty) {
          await db!.insert(symTour, {
            symName: _blankTour.name,
            symDesc: _blankTour.desc,
            symRevision: currentRevision.bytes,
            symCreated: currentRevision.bytes,
          });

          return _blankTour;
        } else {
          return Tour._fromRow(rows[0]);
        }
      },
      createObject: (state) => DbTour._(state),
    );
  }
}

class DbTour extends DbObject<DbTourAccessor, TourId, Tour> {
  DbTour._(DbObjectState<TourId, Tour> state)
      : super((self) => DbTourAccessor(self), state);
}

class DbTourAccessor {
  DbTourAccessor(this.object);

  final DbObject<DbTourAccessor, TourId, Tour> object;
  late final DbObjectState<TourId, Tour> state = object.state!;

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
    await state.db.db!.update(
      symTour,
      {
        ...state.data._toRow(),
        symRevision: state.db.currentRevision.bytes,
      },
    );

    state.notify(object);
  }
}
