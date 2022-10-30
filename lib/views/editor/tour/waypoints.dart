import 'dart:async';

import 'package:builder/widgets/number_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/asset_db/asset_db.dart';
import '/db/db.dart';
import '/db/models/waypoint.dart';
import '/widgets/asset_picker.dart';
import '/widgets/gallery_editor/gallery_editor.dart';
import '/widgets/location_field.dart';
import '/widgets/modal.dart';

class Waypoints extends StatefulWidget {
  const Waypoints({super.key});

  @override
  State<Waypoints> createState() => _WaypointsState();
}

class _WaypointsState extends State<Waypoints> {
  Uuid? selectedWaypoint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _WaypointList(
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
    super.key,
    required this.selectWaypoint,
  });

  final void Function(Uuid?) selectWaypoint;

  @override
  State<_WaypointList> createState() => _WaypointListState();
}

class _WaypointListState extends State<_WaypointList> {
  StreamSubscription<Event>? _eventsSubscription;

  List<PointSummary> _waypoints = [];

  @override
  void initState() {
    super.initState();

    var db = context.read<Future<EvresiDatabase>>();

    (() async {
      if (_eventsSubscription == null) {
        _eventsSubscription = (await db).events.listen(_onEvent);
        (await db).requestEvent(const WaypointsEventDescriptor());
      }
    })();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _onEvent(Event event) {
    if (event.desc == const WaypointsEventDescriptor()) {
      setState(() {
        _waypoints = event.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var db = context.watch<Future<EvresiDatabase>>();

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
                onPressed: () async {
                  (await db).createWaypoint(
                    Waypoint(
                      name: "Untitled",
                      desc: "",
                      lat: 0,
                      lng: 0,
                      triggerRadius: 30,
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
  final PointSummary summary;
  final void Function() onTap;

  @override
  State<_Waypoint> createState() => _WaypointState();
}

class _WaypointState extends State<_Waypoint> {
  @override
  Widget build(BuildContext context) {
    var db = context.watch<Future<EvresiDatabase>>();

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
              const Expanded(child: SizedBox()),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () async {
                  (await db).deleteWaypoint(widget.summary.id);
                },
                child: const Icon(Icons.delete),
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
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  hoverColor: Color(0xFFFFFFFF),
);

class _WaypointEditor extends StatefulWidget {
  const _WaypointEditor({
    super.key,
    required this.selectedWaypoint,
    required this.selectWaypoint,
  });

  final Uuid? selectedWaypoint;
  final void Function(Uuid?) selectWaypoint;

  @override
  State<StatefulWidget> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<_WaypointEditor> {
  DbWaypoint? waypoint;

  @override
  void dispose() {
    waypoint?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WaypointEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedWaypoint != oldWidget.selectedWaypoint) {
      if (widget.selectedWaypoint != null) {
        context
            .read<Future<EvresiDatabase>>()
            .then((db) => db.waypoint(widget.selectedWaypoint!))
            .then((value) {
          waypoint?.dispose();
          value?.listen((() => setState(() {})));
          setState(() => waypoint = value);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.selectedWaypoint != null ? 1.0 : 0.0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: widget.selectedWaypoint == null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Modal(
            title: const Text("Edit Waypoint"),
            child: Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: _waypointEditorInputDecoration.copyWith(
                          labelText: "Title"),
                      controller: TextEditingController(
                          text: waypoint?.data?.name ?? ""),
                      onChanged: (name) {
                        waypoint!.data!.name = name;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      decoration: _waypointEditorInputDecoration.copyWith(
                          labelText: "Description"),
                      minLines: 4,
                      maxLines: 4,
                      controller: TextEditingController(
                          text: waypoint?.data?.desc ?? ""),
                      onChanged: (desc) {
                        waypoint!.data!.desc = desc;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    LocationField(
                      point: waypoint,
                    ),
                    const SizedBox(height: 16.0),
                    NumberField(
                      labelText: "Trigger Radius",
                      value: waypoint?.data?.triggerRadius ?? 0,
                      requestValueChange: (newValue) {
                        waypoint!.data!.triggerRadius = newValue;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    AssetPicker(
                      selectedAssetName: waypoint?.data?.narrationPath,
                      onAssetSelected: (asset) {
                        waypoint?.data?.narrationPath = asset.name;
                      },
                      type: AssetType.narration,
                    ),
                    const SizedBox(height: 16.0),
                    if (widget.selectedWaypoint != null)
                      GalleryEditor(itemId: widget.selectedWaypoint!),
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
        ),
      ),
    );
  }
}
