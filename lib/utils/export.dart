import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:path/path.dart' as path;

import '/asset_db/asset_db.dart';
import '/router.dart';
import '../db/db.dart';

Future<void> export({
  required void Function() onFinish,
  required Future<List<String>?> Function() promptForSourceFiles,
  required Future<String?> Function() promptForDestFile,
}) async {
  var sourceFiles = await promptForSourceFiles();
  if (sourceFiles == null) return;

  var jsonString = await exportToJson(sourceFiles);

  onFinish();
  var destFile = await promptForDestFile();
  if (destFile == null) return;

  await File(destFile).writeAsString(jsonString);
}

Future<String> exportToJson(List<String> paths) async {
  var db = EvresiDatabase();
  var router = ValhallaRouter();

  var json = {
    "tours": [],
    "pois": [],
  };

  for (var dbPath in paths) {
    var ext = path.extension(dbPath);
    late EvresiDatabaseType type;
    if (ext == ".evtour") {
      type = EvresiDatabaseType.tour;
    } else if (ext == ".evpoi") {
      type = EvresiDatabaseType.poiSet;
    } else {
      continue;
    }

    await db.open(dbPath, type);

    if (db.type == EvresiDatabaseType.tour) {
      var tour = await db.tour();

      tour!;

      var tourObj = <String, dynamic>{
        "name": tour.data!.name,
        "desc": tour.data!.desc,
        "waypoints": [],
      };

      var tourGallery = await db.gallery(Uuid.zero);
      tourObj["gallery"] = tourGallery!.data!.list();
      tourGallery.dispose();

      var waypoints = await db.listWaypoints();

      for (var waypointWithId in waypoints) {
        var id = waypointWithId.id;
        var waypoint = waypointWithId.waypoint;

        var waypointObj = {
          "name": waypoint.name,
          "desc": waypoint.desc,
          "lat": waypoint.lat,
          "lng": waypoint.lng,
          "narration": waypoint.narrationPath,
        };

        var waypointGallery = await db.gallery(id);
        waypointObj["gallery"] = waypointGallery!.data!.list();
        waypointGallery.dispose();

        tourObj["waypoints"]!.add(waypointObj);
      }

      var path = await router
          .route(waypoints.map((w) => LatLng(w.waypoint.lat, w.waypoint.lng)));

      var pathString = mtk.PolygonUtil.encode(path
          .map((ll) => mtk.LatLng(ll.latitude, ll.longitude))
          .toList(growable: false));

      tourObj["path"] = pathString;

      json["tours"]!.add(tourObj);

      tour.dispose();
    } else if (db.type == EvresiDatabaseType.poiSet) {
      for (var poiWithId in await db.listPois()) {
        var id = poiWithId.id;
        var poi = poiWithId.poi;

        var poiObj = {
          "name": poi.name,
          "desc": poi.desc,
          "lat": poi.lat,
          "lng": poi.lng,
        };

        var poiGallery = await db.gallery(id);
        poiObj["gallery"] = poiGallery!.data!.list();
        poiGallery.dispose();

        json["pois"]!.add(poiObj);
      }
    }

    await db.close();
  }

  router.dispose();

  return jsonEncode(json);
}

Future<void> bundle(String outputPath, List<String> assetNames) async {
  await compute<_Message, void>(_runBundle, _Message(outputPath, assetNames));
}

Future<void> _runBundle(_Message message) async {
  var zipEncoder = ZipFileEncoder();

  zipEncoder.open(message.outputPath);

  var assets = await assetDbInstance.list();
  assets.removeWhere((element) => !message.assetNames.contains(element.name));
  for (var asset in assets) {
    zipEncoder.addFile(File(asset.fullPath), asset.name);
  }

  zipEncoder.close();
}

class _Message {
  const _Message(this.outputPath, this.assetNames);

  final String outputPath;
  final List<String> assetNames;
}
