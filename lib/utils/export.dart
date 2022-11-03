import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;

import '/asset_db/asset_db.dart';
import '/router.dart';
import '../db/db.dart';

Future<void> export({
  required Future<EvresiDatabase> db,
  required List<String> sourcePoiSets,
  required Future<String?> Function() promptForDestFile,
}) async {
  var tourDb = await db;

  var usedAssets = <String>[];

  var tour = await _tourToJsonObject(tourDb);

  usedAssets.addAll(await _tourUsedAssets(tourDb));

  var pois = [];
  for (var poiSetPath in sourcePoiSets) {
    var poiDb =
        await EvresiDatabase.open(poiSetPath, EvresiDatabaseType.poiSet);

    pois.addAll(await _poiSetToJsonObject(poiDb));

    usedAssets.addAll(await _poiSetUsedAssets(poiDb));

    await poiDb.close();
  }

  var json = jsonEncode({
    ...tour,
    "pois": pois,
  });

  var destFile = await promptForDestFile();

  if (destFile != null) {
    await bundle(destFile, usedAssets, json);
  }
}

Future<List<String>> _poiSetUsedAssets(EvresiDatabase poiDb) async {
  var usedAssets = <String>[];

  for (var poiWithId in await poiDb.listPois()) {
    var id = poiWithId.id;

    var gallery = await poiDb.gallery(id);
    usedAssets.addAll(gallery!.data!.list());
    gallery.dispose();
  }

  return usedAssets;
}

Future<dynamic> _poiSetToJsonObject(EvresiDatabase poiDb) async {
  var json = [];

  for (var poiWithId in await poiDb.listPois()) {
    var id = poiWithId.id;
    var poi = poiWithId.poi;

    var poiObj = {
      "name": poi.name,
      "desc": poi.desc,
      "lat": poi.lat,
      "lng": poi.lng,
    };

    var poiGallery = await poiDb.gallery(id);
    poiObj["gallery"] = poiGallery!.data!.list();
    poiGallery.dispose();

    json.add(poiObj);
  }

  return json;
}

Future<List<String>> _tourUsedAssets(EvresiDatabase tourDb) async {
  var usedAssets = <String>[];

  var tourGallery = await tourDb.gallery(Uuid.zero);
  usedAssets.addAll(tourGallery!.data!.list());
  tourGallery.dispose();

  for (var waypointWithId in await tourDb.listWaypoints()) {
    var id = waypointWithId.id;

    if (waypointWithId.waypoint.narrationPath != null) {
      usedAssets.add(waypointWithId.waypoint.narrationPath!);
    }

    var waypointGallery = await tourDb.gallery(id);
    usedAssets.addAll(waypointGallery!.data!.list());
    waypointGallery.dispose();
  }

  return usedAssets;
}

Future<dynamic> _tourToJsonObject(EvresiDatabase tourDb) async {
  var router = ValhallaRouter();

  var tour = (await tourDb.tour())!;

  var json = <String, dynamic>{
    "name": tour.data!.name,
    "desc": tour.data!.desc,
    "waypoints": [],
  };

  var tourGallery = await tourDb.gallery(Uuid.zero);
  json["gallery"] = tourGallery!.data!.list();
  tourGallery.dispose();

  var waypoints = await tourDb.listWaypoints();

  for (var waypointWithId in waypoints) {
    var id = waypointWithId.id;
    var waypoint = waypointWithId.waypoint;

    var waypointObj = {
      "name": waypoint.name,
      "desc": waypoint.desc,
      "lat": waypoint.lat,
      "lng": waypoint.lng,
      "narration": waypoint.narrationPath,
      "trigger_radius": waypoint.triggerRadius,
      "transcript": waypoint.transcript,
    };

    var waypointGallery = await tourDb.gallery(id);
    waypointObj["gallery"] = waypointGallery!.data!.list();
    waypointGallery.dispose();

    json["waypoints"]!.add(waypointObj);
  }

  var tourPath = await router
      .route(waypoints.map((w) => LatLng(w.waypoint.lat, w.waypoint.lng)));

  var pathString = mtk.PolygonUtil.encode(tourPath
      .map((ll) => mtk.LatLng(ll.latitude, ll.longitude))
      .toList(growable: false));

  json["path"] = pathString;

  tour.dispose();

  return json;
}

Future<void> bundle(
    String outputPath, List<String> assetNames, String tourJson) async {
  await compute<_Message, void>(
      _runBundle, _Message(outputPath, assetNames, tourJson, assetDbInstance));
}

Future<void> _runBundle(_Message message) async {
  var zipEncoder = ZipFileEncoder();

  zipEncoder.open(message.outputPath);

  try {
    var assets = await message.assetDb.list();
    assets.removeWhere((element) => !message.assetNames.contains(element.name));
    for (var asset in assets) {
      zipEncoder.addFile(File(asset.fullPath), "assets/${asset.name}");
    }

    zipEncoder
        .addArchiveFile(ArchiveFile.string("tour.json", message.tourJson));
  } finally {
    zipEncoder.close();
  }
}

class _Message {
  const _Message(this.outputPath, this.assetNames, this.tourJson, this.assetDb);

  final String outputPath;
  final List<String> assetNames;
  final String tourJson;
  final AssetDb assetDb;
}
