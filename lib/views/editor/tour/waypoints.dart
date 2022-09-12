import 'dart:async';

import '/models/editor/tour.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/db/db.dart' as db;

class Waypoints extends StatelessWidget {
  const Waypoints({
    super.key,
    required this.tourId,
  });

  final db.Uuid tourId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _WaypointList(tourId: tourId),
        const UnconstrainedBox(
          constrainedAxis: Axis.horizontal,
          child: _WaypointEditor(),
        ),
      ],
    );
  }
}

class _WaypointList extends StatefulWidget {
  const _WaypointList({
    Key? key,
    required this.tourId,
  }) : super(key: key);

  final db.Uuid tourId;

  @override
  State<_WaypointList> createState() => _WaypointListState();
}

class _WaypointListState extends State<_WaypointList> {
  StreamSubscription<db.Event>? _eventsSubscription;

  List<db.PointSummary> _waypoints = [];

  @override
  void initState() {
    super.initState();
    _eventsSubscription = db.instance.events.listen(_onEvent);
    db.instance
        .requestEvent(db.WaypointsEventDescriptor(tourId: widget.tourId));
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _onEvent(db.Event event) {
    if (event.desc == db.WaypointsEventDescriptor(tourId: widget.tourId)) {
      setState(() {
        _waypoints = event.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _waypoints.length + 1,
      itemBuilder: (context, index) {
        if (index < _waypoints.length) {
          return _Waypoint(
            key: ValueKey(_waypoints[index].id),
            index: index,
            onTap: () => context
                .read<TourEditorModel>()
                .selectWaypoint(_waypoints[index].id),
            summary: _waypoints[index],
          );
        } else {
          return UnconstrainedBox(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () {
                  db.instance.createWaypoint(
                    widget.tourId,
                    db.Waypoint(
                      name: "New waypoint",
                      desc: "",
                      lat: 0,
                      lng: 0,
                      narrationPath: null,
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Icon(Icons.add),
                    SizedBox(width: 16.0),
                    Text("Create Waypoint"),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _Waypoint extends StatefulWidget {
  const _Waypoint({
    Key? key,
    required this.index,
    required this.summary,
    required this.onTap,
  }) : super(key: key);

  final int index;
  final db.PointSummary summary;
  final void Function() onTap;

  @override
  State<_Waypoint> createState() => _WaypointState();
}

class _WaypointState extends State<_Waypoint> {
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.summary.id),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16.0),
              Text(
                "${widget.index + 1}.",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4.0),
              Text(
                widget.summary.name!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Expanded(child: Container()),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () {},
                child: const Icon(Icons.location_pin),
              ),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () {
                  widget.onTap();
                },
                child: const Icon(Icons.edit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaypointEditor extends StatefulWidget {
  const _WaypointEditor({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<_WaypointEditor> {
  db.Uuid? waypointId;
  db.Waypoint? waypoint;

  @override
  Widget build(BuildContext context) {
    var tourEditorModel = context.watch<TourEditorModel>();

    if (tourEditorModel.selectedWaypoint != waypointId) {
      waypointId = tourEditorModel.selectedWaypoint;

      if (waypointId != null) {
        db.instance
            .loadWaypoint(waypointId!)
            .then((value) => setState(() => waypoint = value));
      }
    }

    return AnimatedScale(
      scale: tourEditorModel.selectedWaypoint != null ? 1.0 : 0.0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: tourEditorModel.selectedWaypoint == null,
        child: Card(
          elevation: 4.0,
          margin: const EdgeInsets.all(32.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        hoverColor: Color(0xFFFFFFFF),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelAlignment: FloatingLabelAlignment.start,
                        isDense: true,
                        labelText: "Title",
                      ),
                      controller: TextEditingController(text: waypoint?.name!),
                      onChanged: (name) {
                        waypoint!.name = name;
                        db.instance.updateWaypoint(
                            tourEditorModel.tourId, waypointId!, waypoint!);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        hoverColor: Color(0xFFFFFFFF),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelAlignment: FloatingLabelAlignment.start,
                        isDense: true,
                        labelText: "Description",
                      ),
                      minLines: 4,
                      maxLines: 4,
                      controller: TextEditingController(text: waypoint?.desc!),
                      onChanged: (desc) {
                        waypoint!.desc = desc;
                        db.instance.updateWaypoint(
                            tourEditorModel.tourId, waypointId!, waypoint!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  child: UnconstrainedBox(
                    child: Row(
                      children: const [
                        Icon(Icons.check),
                        SizedBox(width: 16.0),
                        Text("Done"),
                      ],
                    ),
                  ),
                  onPressed: () => tourEditorModel.selectWaypoint(null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}