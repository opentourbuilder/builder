import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;

import '/asset_db/asset_db.dart';
import '/router.dart';
import '../db/db.dart';

class _ContentExporter {
  _ContentExporter(this._tourDb, this._poiSetPaths);

  final EvresiDatabase _tourDb;
  final List<String> _poiSetPaths;
  final Map<String, String> _assetRenameMap = {};

  Future<_ContentExport> export() async {
    var tour = await _buildTourJson();

    var pois = [];
    for (var poiSetPath in _poiSetPaths) {
      var poiDb =
          await EvresiDatabase.open(poiSetPath, EvresiDatabaseType.poiSet);
      pois.addAll(await _buildPoiSetJson(poiDb));
      poiDb.close();
    }

    var tourJson = jsonEncode({
      ...tour,
      "pois": pois,
    });

    var assetsJson = jsonEncode(await _buildAssetsJson());

    return _ContentExport(
      tourJson: tourJson,
      assetsJson: assetsJson,
      assetRenameMap: _assetRenameMap,
    );
  }

  Future<Map<dynamic, dynamic>> _buildTourJson() async {
    var router = ValhallaRouter();

    var waypoints = await _tourDb.listWaypoints();
    var tourPath = await router
        .route(waypoints.map((w) => LatLng(w.waypoint.lat, w.waypoint.lng)));

    var pathString = mtk.PolygonUtil.encode(tourPath
        .map((ll) => mtk.LatLng(ll.latitude, ll.longitude))
        .toList(growable: false));

    return await (await _tourDb.tour())!.use((data) async {
      return {
        "name": data.name,
        "desc": data.desc,
        "waypoints": [
          for (var it in waypoints)
            {
              "name": it.waypoint.name,
              "desc": it.waypoint.desc,
              "lat": it.waypoint.lat,
              "lng": it.waypoint.lng,
              "narration": it.waypoint.narrationPath != null
                  ? await _renameAsset(it.waypoint.narrationPath!)
                  : null,
              "trigger_radius": it.waypoint.triggerRadius,
              "transcript": it.waypoint.transcript,
              "gallery": await (await _tourDb.gallery(it.id))
                  .use((data) => data.list())
                  .map(_renameAsset)
                  .waitAll(),
            }
        ],
        "gallery": await (await _tourDb.gallery(Uuid.zero))
            .use((data) => data.list())
            .map(_renameAsset)
            .waitAll(),
        "path": pathString,
      };
    });
  }

  Future<List<dynamic>> _buildPoiSetJson(EvresiDatabase poiDb) async {
    return [
      for (var it in await poiDb.listPois())
        {
          "name": it.poi.name,
          "desc": it.poi.desc,
          "lat": it.poi.lat,
          "lng": it.poi.lng,
          "gallery": await (await poiDb.gallery(it.id))
              .use((data) => data.list())
              .map(_renameAsset)
              .waitAll(),
        },
    ];
  }

  Future<Map<dynamic, dynamic>> _buildAssetsJson() async {
    var assets = {};

    for (var assetRename in _assetRenameMap.entries) {
      var asset = (await assetDbInstance.asset(assetRename.key))!;

      assets[assetRename.value] = {
        "attribution": await asset.attribution,
        "alt": await asset.alt,
      };
    }

    return {
      "assets": assets,
    };
  }

  Future<String> _renameAsset(String assetName) async {
    if (!_assetRenameMap.containsKey(assetName)) {
      var asset = (await assetDbInstance.asset(assetName))!;
      _assetRenameMap[assetName] =
          "${await asset.calculateHash()}${asset.extension}";
    }

    return _assetRenameMap[assetName]!;
  }
}

class _ContentExport {
  _ContentExport({
    required this.tourJson,
    required this.assetsJson,
    required this.assetRenameMap,
  });

  final String tourJson;
  final String assetsJson;
  final Map<String, String> assetRenameMap;
}

Future<void> export({
  required Future<EvresiDatabase> db,
  required List<String> sourcePoiSets,
  required Future<String?> Function() promptForDestFile,
}) async {
  var tourDb = await db;

  var contentExport = await _ContentExporter(tourDb, sourcePoiSets).export();

  var destFilename = await promptForDestFile();
  if (destFilename != null) {
    await _bundle(destFilename, contentExport);
  }
}

Future<void> _bundle(String outputPath, _ContentExport contentExport) async {
  await compute<_Message, void>(
      _runBundle, _Message(outputPath, contentExport, assetDbInstance));
}

Future<void> _runBundle(_Message message) async {
  var zipEncoder = ZipFileEncoder();

  zipEncoder.open(message.outputPath);

  try {
    var assets = await message.assetDb.list();
    assets.removeWhere((element) =>
        !message.contentExport.assetRenameMap.keys.contains(element.name));
    for (var asset in assets) {
      var newName = message.contentExport.assetRenameMap[asset.name];
      zipEncoder.addFile(File(asset.localPath), "assets/$newName");
    }

    zipEncoder.addArchiveFile(
        ArchiveFile.string("tour.json", message.contentExport.tourJson));
    zipEncoder.addArchiveFile(
        ArchiveFile.string("assets.json", message.contentExport.assetsJson));
  } finally {
    zipEncoder.close();
  }
}

class _Message {
  const _Message(
    this.outputPath,
    this.contentExport,
    this.assetDb,
  );

  final String outputPath;
  final _ContentExport contentExport;
  final AssetDb assetDb;
}

extension WaitAll<T> on Iterable<Future<T>> {
  Future<Iterable<T>> waitAll() {
    return Future.wait(this);
  }
}
