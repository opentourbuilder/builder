import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
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
    ".mp3": AssetType.narration,
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
  const Asset(this.name, this._localPathBase);

  final String name;
  final String _localPathBase;

  AssetType get type => AssetType.extensionMap[path.extension(name)]!;
  String get extension => path.extension(name);
  String get localPath => path.join(_localPathBase, name);

  Future<String?> get attribution async {
    var attribPath = path.join(_localPathBase, "$name.attrib.txt");

    var attribFile = File(attribPath);

    if (await attribFile.exists()) {
      return await attribFile.readAsString();
    } else {
      return null;
    }
  }

  Future<void> setAttribution(String? value) async {
    var attribPath = path.join(_localPathBase, "$name.attrib.txt");

    if (value == null) {
      try {
        await File(attribPath).delete();
      } on FileSystemException catch (_) {
        // Don't care if the file didn't exist
      }
    } else {
      await File(attribPath).writeAsString(value);
    }
  }

  Future<String?> get alt async {
    var altPath = path.join(_localPathBase, "$name.alt.txt");

    var altFile = File(altPath);

    if (await altFile.exists()) {
      return await altFile.readAsString();
    } else {
      return null;
    }
  }

  Future<void> setAlt(String? value) async {
    var altPath = path.join(_localPathBase, "$name.alt.txt");

    if (value == null) {
      try {
        await File(altPath).delete();
      } on FileSystemException catch (_) {
        // Don't care if the file didn't exist
      }
    } else {
      await File(altPath).writeAsString(value);
    }
  }

  Future<void> delete() async {
    var attribPath = path.join(_localPathBase, "$name.attrib.txt");
    var altPath = path.join(_localPathBase, "$name.alt.txt");

    try {
      await File(localPath).delete();
      await File(attribPath).delete();
      await File(altPath).delete();
    } on FileSystemException catch (_) {
      // Don't care if any of the files didn't exist
    }
  }

  Future<String> calculateHash() async {
    var output = AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);

    await for (var chunk in File(localPath).openRead()) {
      input.add(chunk);
    }

    input.close();

    var digest = output.events.single;

    return digest.toString();
  }
}

class AssetDb {
  AssetDb(this.assetsPath);

  final String assetsPath;

  Future<List<Asset>> list([String query = "", AssetType? queryType]) async {
    query = query.toLowerCase();

    var results = <Asset>[];

    await for (var asset in Directory(assetsPath).list()) {
      if (asset is! File) continue;

      var name = path.basename(asset.path);

      if (!name.toLowerCase().contains(query)) continue;

      var type = AssetType.extensionMap[path.extension(asset.path)];

      if (type != null && (queryType == null || type == queryType)) {
        results.add(Asset(name, assetsPath));
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
    await srcFile.copy(path.join(assetsPath, assetName));

    return Asset(assetName, assetsPath);
  }
}
