import 'dart:convert';
import 'dart:io';

import 'data/tour.dart';

class OpenTour {
  final String _path;
  final TourModel data;

  OpenTour._(this._path, this.data);

  static Future<OpenTour> load(String path) async {
    var text = await File(path).readAsString();
    var data = jsonDecode(text);
    return OpenTour._(path, TourModel.fromJson(data));
  }

  Future<void> saveChanges() async {
    var text = jsonEncode(data);
    await File(_path).writeAsString(text);
  }
}
