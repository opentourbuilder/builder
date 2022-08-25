import 'dart:async';

import 'package:flutter/material.dart';

import '/db/db.dart';
import 'tour/map.dart';
import 'tour/waypoint_list.dart';

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
  List<PointSummary> waypoints = [];
  StreamSubscription<Event>? _eventsSubscription;

  final _contentEditorKey = GlobalKey();
  final _mapKey = GlobalKey();

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

    return LayoutBuilder(builder: (context, constraints) {
      final contentEditor = _TourContentEditor(
        key: _contentEditorKey,
        tourId: widget.tourId,
        tour: _tour,
        waypoints: waypoints,
        onTourNameChanged: (value) {
          _tour?.name = value;
          _updateSaveTimer();
        },
        onTourDescChanged: (value) {
          _tour?.desc = value;
          _updateSaveTimer();
        },
      );

      final map = TourMap(
        key: _mapKey,
        waypoints: waypoints,
        tourId: widget.tourId,
      );

      if (constraints.maxWidth >= 800) {
        return Row(
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
        return DefaultTabController(
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
    });
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

class _TourContentEditor extends StatelessWidget {
  const _TourContentEditor({
    Key? key,
    required this.tourId,
    required this.tour,
    required this.waypoints,
    required this.onTourDescChanged,
    required this.onTourNameChanged,
  }) : super(key: key);

  final Uuid tourId;
  final Tour? tour;
  final List<PointSummary> waypoints;
  final void Function(String) onTourNameChanged;
  final void Function(String) onTourDescChanged;

  @override
  Widget build(BuildContext context) {
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
                    enabled: tour != null,
                    controller: tour != null
                        ? TextEditingController(text: tour!.name)
                        : null,
                    onChanged: tour != null ? onTourNameChanged : null,
                    decoration: inputDecoration.copyWith(labelText: "Title"),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    minLines: 8,
                    maxLines: 8,
                    enabled: tour != null,
                    controller: tour != null
                        ? TextEditingController(text: tour!.desc)
                        : null,
                    onChanged: tour != null ? onTourDescChanged : null,
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
                WaypointList(
                  tourId: tourId,
                  waypoints: waypoints,
                ),
                const Text("Bbbbbbbbbbbbbbbbbb"),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
