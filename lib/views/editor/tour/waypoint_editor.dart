import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/db/db.dart';
import '/models/editor/tour.dart';

class WaypointEditor extends StatefulWidget {
  const WaypointEditor({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<WaypointEditor> {
  Uuid? waypointId;
  Waypoint? waypoint;

  @override
  Widget build(BuildContext context) {
    var tourEditorModel = context.watch<TourEditorModel>();

    if (tourEditorModel.selectedWaypoint != waypointId) {
      waypointId = tourEditorModel.selectedWaypoint;

      if (waypointId != null) {
        db
            .loadWaypoint(waypointId!)
            .then((value) => setState(() => waypoint = value));
      }
    }

    if (waypoint == null) return const SizedBox();

    return _WaypointEditorContainer(
      child: Column(
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
            controller: TextEditingController(text: waypoint!.name!),
            onChanged: (name) {
              waypoint!.name = name;
              db.updateWaypoint(tourEditorModel.tourId, waypointId!, waypoint!);
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
            controller: TextEditingController(text: waypoint!.desc!),
            onChanged: (desc) {
              waypoint!.desc = desc;
              db.updateWaypoint(tourEditorModel.tourId, waypointId!, waypoint!);
            },
          ),
        ],
      ),
    );
  }
}

class _WaypointEditorContainer extends StatelessWidget {
  const _WaypointEditorContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var tourEditorModel = context.watch<TourEditorModel>();

    return AnimatedScale(
      scale: tourEditorModel.selectedWaypoint != null ? 1.0 : 0.0,
      curve: Curves.easeInOutQuart,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: tourEditorModel.selectedWaypoint == null,
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(32.0),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    splashRadius: 16.0,
                    padding: const EdgeInsets.all(12.0),
                    icon: const Icon(Icons.close),
                    onPressed: () => tourEditorModel.selectWaypoint(null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
