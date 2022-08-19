import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '../../db/db.dart';

class TourEditor extends StatefulWidget {
  const TourEditor({Key? key, required this.tourId}) : super(key: key);

  final Uuid tourId;

  @override
  State<TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<TourEditor> {
  Timer? _saveTimer;
  Tour? _tour;
  bool _tourLoaded = false;

  @override
  void initState() {
    super.initState();
    db.loadTour(widget.tourId).then((tour) {
      setState(() {
        _tour = tour;
        _tourLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tourLoaded && _tour == null) {
      // TODO: show error popup
      throw Exception("Error: loaded tour is null");
    }

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: FloatingLabelAlignment.start,
      isDense: true,
    );

    var inputsEnabled = _tour != null && _tourLoaded;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            enabled: inputsEnabled,
            controller:
                inputsEnabled ? TextEditingController(text: _tour!.name) : null,
            onChanged: inputsEnabled
                ? (value) {
                    _tour!.name = value;
                    _updateSaveTimer();
                  }
                : null,
            decoration: inputDecoration.copyWith(labelText: "Title"),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    minLines: 8,
                    maxLines: 8,
                    enabled: inputsEnabled,
                    controller: inputsEnabled
                        ? TextEditingController(text: _tour!.desc)
                        : null,
                    onChanged: inputsEnabled
                        ? (value) {
                            _tour!.desc = value;
                            _updateSaveTimer();
                          }
                        : null,
                    decoration:
                        inputDecoration.copyWith(labelText: "Description"),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(37.09024, -95.712891),
                      zoom: 4,
                      maxZoom: 18,
                    ),
                    layers: [
                      TileLayerOptions(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'org.evresi.builder',
                      ),
                    ],
                    nonRotatedChildren: [
                      AttributionWidget.defaultWidget(
                        source: 'OpenStreetMap contributors',
                        onSourceTapped: null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      db.updateTour(widget.tourId, _tour!);
    });
  }
}
