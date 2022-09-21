import 'dart:collection';

import '../db.dart';

class Gallery {
  Gallery(this.list);

  List<String> list;
}

class GalleryId {
  const GalleryId(this.itemId);

  final Uuid itemId;

  @override
  operator ==(Object other) => other is GalleryId && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(runtimeType, itemId);
}

class DbGalleryInfo extends DbObjectInfo<GalleryId, Gallery, DbGalleryInfo> {
  DbGalleryInfo({required super.id, required super.data});

  static Future<DbGalleryInfo?> load(GalleryId id) async {
    var items = await instance.db.query(
      symGallery,
      columns: [symItem, symPath, symOrder],
      where: "$symItem = ?",
      whereArgs: [id.itemId.bytes],
      orderBy: symOrder,
    );

    return DbGalleryInfo(
      id: id,
      data: Gallery([...items.map((e) => e[symPath]! as String)]),
    );
  }
}

class DbGallery extends DbObject<GalleryId, Gallery, DbGalleryInfo> {
  DbGallery(super.info);

  int get length => info!.data.list.length;

  String operator [](int index) => info!.data.list[index];
  operator []=(int index, String value) {
    info!.data.list[index] = value;

    instance.db.update(
      symGallery,
      {
        symPath: value,
      },
      where: "$symItem = ? AND $symOrder = ?",
      whereArgs: [info!.id.itemId.bytes, index],
    );
  }

  void add(String path) {
    var order = info!.data.list.length;

    info!.data.list.add(path);

    instance.db.insert(symGallery, {
      symItem: info!.id.itemId.bytes,
      symPath: path,
      symOrder: order,
    });
  }

  void reorder(Iterable<String> paths) {
    var allPaths = [
      ...paths,
      ...[...info!.data.list]..removeWhere((path) => paths.contains(path)),
    ];

    info!.data.list = allPaths;

    var batch = instance.db.batch();

    int order = 0;
    for (var path in allPaths) {
      batch.update(
        symGallery,
        {
          symOrder: order++,
        },
        where: "$symItem = ? AND $symPath = ?",
        whereArgs: [info!.id.itemId.bytes, path],
      );
    }

    batch.commit();
  }

  void remove(int index) {
    var path = info!.data.list.removeAt(index);

    instance.db.delete(
      symGallery,
      where: "$symItem = ? AND $symPath = ?",
      whereArgs: [info!.id.itemId.bytes, path],
    );

    reorder(info!.data.list);
  }
}
