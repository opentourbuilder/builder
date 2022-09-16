import 'dart:async';
import 'dart:math';

import 'package:builder/db/models/waypoint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/db/db.dart' as db;
import '/models/editor/tour.dart';
import '/widgets/modal.dart';

class Waypoints extends StatefulWidget {
  const Waypoints({
    super.key,
    required this.tourId,
  });

  final db.Uuid tourId;

  @override
  State<Waypoints> createState() => _WaypointsState();
}

class _WaypointsState extends State<Waypoints> {
  db.Uuid? selectedWaypoint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _WaypointList(
          tourId: widget.tourId,
          selectWaypoint: (id) => setState(() => selectedWaypoint = id),
        ),
        _WaypointEditor(
          selectedWaypoint: selectedWaypoint,
          selectWaypoint: (id) => setState(() => selectedWaypoint = id),
        ),
      ],
    );
  }
}

class _WaypointList extends StatefulWidget {
  const _WaypointList({
    Key? key,
    required this.tourId,
    required this.selectWaypoint,
  }) : super(key: key);

  final db.Uuid tourId;
  final void Function(db.Uuid?) selectWaypoint;

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
      padding: const EdgeInsets.all(12.0),
      itemCount: _waypoints.length + 1,
      itemBuilder: (context, index) {
        if (index < _waypoints.length) {
          return _Waypoint(
            key: ValueKey(_waypoints[index].id),
            index: index,
            onTap: () => widget.selectWaypoint(_waypoints[index].id),
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
                    Waypoint(
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

const _waypointEditorInputDecoration = InputDecoration(
  border: OutlineInputBorder(),
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  hoverColor: Color(0xFFFFFFFF),
  floatingLabelBehavior: FloatingLabelBehavior.always,
  floatingLabelAlignment: FloatingLabelAlignment.start,
  isDense: true,
);

class _WaypointEditor extends StatefulWidget {
  const _WaypointEditor({
    super.key,
    required this.selectedWaypoint,
    required this.selectWaypoint,
  });

  final db.Uuid? selectedWaypoint;
  final void Function(db.Uuid?) selectWaypoint;

  @override
  State<StatefulWidget> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<_WaypointEditor> {
  db.Uuid? waypointId;
  DbWaypoint? waypoint;

  @override
  void dispose() {
    waypoint?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tourEditorModel = context.watch<TourEditorModel>();

    if (widget.selectedWaypoint != waypointId) {
      waypointId = widget.selectedWaypoint;

      if (waypointId != null) {
        db.instance.waypoint(tourEditorModel.tourId, waypointId!).then((value) {
          if (waypoint != null) {
            waypoint?.cancel();
          }
          value?.listen((() => setState(() {})));
          setState(() => waypoint = value);
        });
      }
    }

    return AnimatedScale(
      scale: widget.selectedWaypoint != null ? 1.0 : 0.0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: widget.selectedWaypoint == null,
        child: Modal(
          title: const Text("Edit Waypoint"),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: _waypointEditorInputDecoration.copyWith(
                      labelText: "Title"),
                  controller: TextEditingController(text: waypoint?.name!),
                  onChanged: (name) {
                    waypoint!.name = name;
                  },
                ),
                const SizedBox(height: 16.0),
                TextField(
                  decoration: _waypointEditorInputDecoration.copyWith(
                      labelText: "Description"),
                  minLines: 4,
                  maxLines: 4,
                  controller: TextEditingController(text: waypoint?.desc!),
                  onChanged: (desc) {
                    waypoint!.desc = desc;
                  },
                ),
                const SizedBox(height: 16.0),
                LocationField(
                  lat: waypoint?.lat,
                  lng: waypoint?.lng,
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
                  onPressed: () => widget.selectWaypoint(null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocationField extends StatefulWidget {
  const LocationField({
    super.key,
    required this.lat,
    required this.lng,
  });

  final double? lat;
  final double? lng;

  @override
  State<StatefulWidget> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  bool latBad = false;
  bool lngBad = false;
  double lat = 0;
  double lng = 0;

  @override
  void initState() {
    super.initState();

    latController.addListener(() {
      final String text = latController.text.replaceAll(RegExp(r'[^\d.-]'), "");
      latController.value = latController.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset:
              min(latController.value.selection.baseOffset, text.length),
          extentOffset:
              min(latController.value.selection.extentOffset, text.length),
        ),
      );

      double? newLat = double.tryParse(text);
      setState(() {
        if (newLat != null && newLat >= -90 && newLat <= 90) {
          lat = newLat;
          latBad = false;
        } else {
          latBad = true;
        }
      });
    });
    lngController.addListener(() {
      final String text = lngController.text.replaceAll(RegExp(r'[^\d.-]'), "");
      lngController.value = lngController.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset:
              min(latController.value.selection.baseOffset, text.length),
          extentOffset:
              min(latController.value.selection.extentOffset, text.length),
        ),
      );

      double? newLng = double.tryParse(text);
      setState(() {
        if (newLng != null && newLng >= -180 && newLng <= 180) {
          lng = newLng;
          lngBad = false;
        } else {
          lngBad = true;
        }
      });
    });

    lat = widget.lat ?? 0;
    lng = widget.lng ?? 0;
    latController.text = '$lat';
    lngController.text = '$lng';
  }

  @override
  void didUpdateWidget(covariant LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);

    lat = widget.lat ?? 0;
    lng = widget.lng ?? 0;
    latController.text = '$lat';
    lngController.text = '$lng';
  }

  @override
  void dispose() {
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            decoration: _waypointEditorInputDecoration.copyWith(
              labelText: "Latitude",
              errorText: latBad ? "Must be a number between -90 and 90" : null,
              errorMaxLines: 2,
            ),
            controller: latController,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextField(
            decoration: _waypointEditorInputDecoration.copyWith(
              labelText: "Longitude",
              errorText:
                  lngBad ? "Must be a number between -180 and 180" : null,
              errorMaxLines: 2,
            ),
            controller: lngController,
          ),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: () {},
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.secondary),
          ),
          child: const Icon(Icons.pin_drop),
        ),
      ],
    );
  }
}
