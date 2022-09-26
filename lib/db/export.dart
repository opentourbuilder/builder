import 'dart:convert';

import 'package:path/path.dart' as path;

import 'db.dart';

Future<String> exportToJson(List<String> paths) async {
  EvresiDatabase db = EvresiDatabase();

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

      for (var waypointWithId in await db.listWaypoints()) {
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

  return jsonEncode(json);
}
