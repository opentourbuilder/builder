import 'package:flutter/material.dart';

import '/db/db.dart';

class TourEditorModel extends ChangeNotifier {
  TourEditorModel({required this.tourId});

  Uuid tourId;
  Uuid? _selectedWaypoint;

  Uuid? get selectedWaypoint => _selectedWaypoint;

  void selectWaypoint(Uuid? waypoint) {
    _selectedWaypoint = waypoint;
    notifyListeners();
  }
}
