import '../db.dart';

class GalleryId {
  const GalleryId(this.itemId);

  final Uuid itemId;

  @override
  operator ==(Object other) => other is GalleryId && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(runtimeType, itemId);
}

class Gallery {
  Gallery(this.list);

  List<String> list;
}

mixin EvresiDatabaseGalleryMixin on EvresiDatabaseBase {
  Future<DbGallery?> gallery(Uuid itemId) async {
    return load<DbGallery, GalleryId, Gallery>(
      id: GalleryId(itemId),
      load: () async {
        var items = await db!.query(
          symGallery,
          columns: [symItem, symPath, symOrder],
          where: "$symItem = ?",
          whereArgs: [itemId.bytes],
          orderBy: symOrder,
        );

        return Gallery([...items.map((e) => e[symPath]! as String)]);
      },
      createObject: (state) => DbGallery._(state),
    );
  }
}

class DbGallery extends DbObject<DbGalleryAccessor, GalleryId, Gallery> {
  DbGallery._(DbObjectState<GalleryId, Gallery> state)
      : super((self) => DbGalleryAccessor(self), state);
}

class DbGalleryAccessor {
  DbGalleryAccessor(this.object);

  final DbObject<DbGalleryAccessor, GalleryId, Gallery> object;
  late final DbObjectState<GalleryId, Gallery> state = object.state!;

  int get length => state.data.list.length;

  String operator [](int index) => state.data.list[index];
  operator []=(int index, String value) {
    state.data.list[index] = value;

    instance.db!.update(
      symGallery,
      {
        symPath: value,
      },
      where: "$symItem = ? AND $symOrder = ?",
      whereArgs: [state.id.itemId.bytes, index],
    );
  }

  void add(String path) {
    var order = state.data.list.length;

    state.data.list.add(path);

    instance.db!.insert(symGallery, {
      symItem: state.id.itemId.bytes,
      symPath: path,
      symOrder: order,
    });
  }

  void reorder(Iterable<String> paths) {
    var allPaths = [
      ...paths,
      ...[...state.data.list]..removeWhere((path) => paths.contains(path)),
    ];

    state.data.list = allPaths;

    var batch = instance.db!.batch();

    int order = 0;
    for (var path in allPaths) {
      batch.update(
        symGallery,
        {
          symOrder: order++,
        },
        where: "$symItem = ? AND $symPath = ?",
        whereArgs: [state.id.itemId.bytes, path],
      );
    }

    batch.commit();
  }

  void remove(int index) {
    var path = state.data.list.removeAt(index);

    instance.db!.delete(
      symGallery,
      where: "$symItem = ? AND $symPath = ?",
      whereArgs: [state.id.itemId.bytes, path],
    );

    reorder(state.data.list);
  }
}
