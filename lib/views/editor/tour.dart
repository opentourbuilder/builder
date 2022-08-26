import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/db/db.dart';
import '/models/editor/tour.dart';
import 'tour/map.dart';
import 'tour/waypoint_editor.dart';
import 'tour/waypoint_list.dart';

class TourEditor extends StatefulWidget {
  const TourEditor({Key? key, required this.tourId}) : super(key: key);

  final Uuid tourId;

  @override
  State<TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<TourEditor> {
  final _contentEditorKey = GlobalKey();
  final _mapKey = GlobalKey();

  StreamSubscription<Event>? _eventsSubscription;

  List<PointSummary> waypoints = [];

  @override
  void initState() {
    super.initState();
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
    return LayoutBuilder(builder: (context, constraints) {
      final contentEditor = _TourContentEditor(
        key: _contentEditorKey,
        tourId: widget.tourId,
        waypoints: waypoints,
      );

      final map = TourMap(
        key: _mapKey,
        waypoints: waypoints,
        tourId: widget.tourId,
      );

      Widget child;
      if (constraints.maxWidth >= 800) {
        child = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contentEditor,
            const VerticalDivider(
              width: 1.0,
              thickness: 1.0,
            ),
            Expanded(child: map),
          ],
        );
      } else {
        child = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(child: Text("Content")),
                  Tab(child: Text("Map")),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    contentEditor,
                    map,
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return ChangeNotifierProvider(
        create: (_) => TourEditorModel(tourId: widget.tourId),
        child: child,
      );
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

class _TourContentEditor extends StatefulWidget {
  const _TourContentEditor({
    Key? key,
    required this.tourId,
    required this.waypoints,
  }) : super(key: key);

  final Uuid tourId;
  final List<PointSummary> waypoints;

  @override
  State<_TourContentEditor> createState() => _TourContentEditorState();
}

class _TourContentEditorState extends State<_TourContentEditor> {
  Timer? _saveTimer;

  bool _tourLoaded = false;
  Tour? _tour;

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

    return DefaultTabController(
      length: 2,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    enabled: _tour != null,
                    controller: _tour != null
                        ? TextEditingController(text: _tour!.name)
                        : null,
                    onChanged: _tour != null
                        ? (value) {
                            _tour?.name = value;
                            _updateSaveTimer();
                          }
                        : null,
                    decoration: inputDecoration.copyWith(labelText: "Title"),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    minLines: 8,
                    maxLines: 8,
                    enabled: _tour != null,
                    controller: _tour != null
                        ? TextEditingController(text: _tour!.desc)
                        : null,
                    onChanged: _tour != null
                        ? (value) {
                            _tour?.desc = value;
                            _updateSaveTimer();
                          }
                        : null,
                    decoration:
                        inputDecoration.copyWith(labelText: "Description"),
                  ),
                ],
              ),
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
                Stack(
                  children: [
                    WaypointList(
                      tourId: widget.tourId,
                      waypoints: widget.waypoints,
                    ),
                    const WaypointEditor(),
                  ],
                ),
                const Text("This is where the POI editor goes."),
              ]),
            ),
          ],
        ),
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
