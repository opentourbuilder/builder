import 'package:flutter/material.dart';

class WaypointEditor extends StatefulWidget {
  const WaypointEditor({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaypointEditorState();
}

class _WaypointEditorState extends State<WaypointEditor> {
  @override
  Widget build(BuildContext context) {
    return const Text("Waypoint editor!");
  }
}
