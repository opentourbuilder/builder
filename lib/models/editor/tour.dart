import 'package:flutter/material.dart';

import '/db/db.dart';

class TourEditorModel extends ChangeNotifier {
  TourEditorModel({required this.tourId});

  Uuid tourId;
}
