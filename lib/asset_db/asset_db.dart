import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

late AssetDb _db;

Future<void> initAssetDatabase() async {
  var assetsPath = path.join(
      (await getApplicationDocumentsDirectory()).path, "EvresiProjects");

  await Directory(assetsPath).create(recursive: true);

  _db = AssetDb(assetsPath);
}

AssetDb get assetDbInstance => _db;

enum AssetType {
  image,
  narration;

  static final Map<String, AssetType> extensionMap = Map.unmodifiable({
    ".jpg": AssetType.image,
    ".jpeg": AssetType.image,
    ".png": AssetType.image,
    ".svg": AssetType.image,
    ".ogg": AssetType.narration,
    ".mp3": AssetType.narration,
    ".wav": AssetType.narration,
  });
}

class AssetDbException implements Exception {
  const AssetDbException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class Asset {
  const Asset(this.name, this.type, this.fullPath);

  final String name;
  final AssetType type;
  final String fullPath;
}

class AssetDb {
  AssetDb(this.assetsPath);

  final String assetsPath;

  Future<List<Asset>> list([String query = "", AssetType? queryType]) async {
    query = query.toLowerCase();

    var results = <Asset>[];

    await for (var asset in Directory(assetsPath).list()) {
      if (asset is! File) continue;

      var name = path.basenameWithoutExtension(asset.path);

      if (!name.toLowerCase().contains(query)) continue;

      var type = AssetType.extensionMap[path.extension(asset.path)];

      if (type != null && (queryType == null || type == queryType)) {
        results.add(Asset(name, type, asset.path));
      }
    }

    return results;
  }

  Future<Asset?> asset(String assetName) async {
    var lowercaseAssetName = assetName.toLowerCase();

    List<Asset?> matches =
        // ignore: unnecessary_cast
        (await list(assetName)).map((e) => e as Asset?).toList();

    return matches.firstWhere(
      (asset) => asset!.name.toLowerCase() == lowercaseAssetName,
      orElse: () => null,
    );
  }

  bool validPath(String assetPath) =>
      AssetType.extensionMap.containsKey(path.extension(assetPath));

  Future<Asset> add(String assetName, String assetPath) async {
    var extension = path.extension(assetPath);
    var assetType = AssetType.extensionMap[extension];
    if (assetType == null) {
      throw const AssetDbException("Invalid asset extension!");
    }

    var srcFile = File(assetPath);
    await srcFile.copy(path.join(assetsPath, "$assetName$extension"));

    return Asset(assetName, assetType, assetPath);
  }
}
