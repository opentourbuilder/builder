import 'common.dart';

class TourModel {
  TourModel();

  String title = "";
  String desc = "";
  List<WaypointModel> waypoints = [];

  factory TourModel.fromJson(Map<String, dynamic> data) => TourModel()
    ..title = data["title"]! as String
    ..desc = data["desc"]! as String
    ..waypoints = (data["waypoints"]! as List<Map<String, dynamic>>)
        .map(WaypointModel.fromJson)
        .toList();

  dynamic toJson() => {
        "title": title,
        "desc": desc,
        "waypoints": waypoints,
      };
}

class WaypointModel {
  WaypointModel();

  String title = "";
  String desc = "";
  double lat = 0.0;
  double lng = 0.0;
  AssetModel? narration;
  AssetModel? thumbnail;
  List<AssetModel> gallery = [];

  factory WaypointModel.fromJson(Map<String, dynamic> data) => WaypointModel()
    ..title = data["title"]! as String
    ..desc = data["desc"]! as String
    ..lat = data["lat"]! as double
    ..lng = data["lng"]! as double
    ..narration = data["narration"] != null
        ? AssetModel.fromJson(data["narraton"]! as String)
        : null
    ..thumbnail = data["narration"] != null
        ? AssetModel.fromJson(data["narraton"]! as String)
        : null
    ..gallery =
        (data["gallery"]! as List<String>).map(AssetModel.fromJson).toList();

  dynamic toJson() => {
        "title": title,
        "desc": desc,
        "lat": lat,
        "lng": lng,
        "narration": narration,
        "thumbnail": thumbnail,
        "gallery": gallery,
      };
}
