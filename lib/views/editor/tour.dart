import 'dart:async';

import 'package:flutter/material.dart';

import '/db/db.dart';
import 'tour/map.dart';
import 'tour/waypoints.dart';

class TourEditor extends StatefulWidget {
  const TourEditor({Key? key, required this.tourId}) : super(key: key);

  final Uuid tourId;

  @override
  State<TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<TourEditor>
    with SingleTickerProviderStateMixin<TourEditor> {
  Timer? _saveTimer;
  Tour? _tour;
  bool _tourLoaded = false;
  List<PointSummary> waypoints = [];
  StreamSubscription<Event>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    db.loadTour(widget.tourId).then((tour) {
      setState(() {
        _tour = tour;
        _tourLoaded = true;
      });
    });
    _eventsSubscription = db.events.listen(_onEvent);
    db.requestEvent(WaypointsEventDescriptor(tourId: widget.tourId));
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 500,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TextField(
                    enabled: inputsEnabled,
                    controller: inputsEnabled
                        ? TextEditingController(text: _tour!.name)
                        : null,
                    onChanged: inputsEnabled
                        ? (value) {
                            _tour!.name = value;
                            _updateSaveTimer();
                          }
                        : null,
                    decoration: inputDecoration.copyWith(labelText: "Title"),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
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
                  TabBar(
                    labelColor: Colors.black,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(child: Text("Route")),
                      Tab(child: Text("POIs")),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(children: [
                      WaypointsEditor(
                        tourId: widget.tourId,
                        waypoints: waypoints,
                      ),
                      const Text("Bbbbbbbbbbbbbbbbbb"),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: TourMap(
              waypoints: waypoints,
              tourId: widget.tourId,
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

  void _onEvent(Event event) {
    if (event.desc == WaypointsEventDescriptor(tourId: widget.tourId)) {
      setState(() {
        waypoints = event.value;
      });
    }
  }
}
