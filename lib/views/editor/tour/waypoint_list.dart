import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/db/db.dart';

class WaypointList extends StatelessWidget {
  const WaypointList({
    Key? key,
    required this.tourId,
    required this.waypoints,
    required this.onWaypointTap,
  }) : super(key: key);

  final Uuid tourId;
  final List<PointSummary> waypoints;
  final void Function(Uuid) onWaypointTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: waypoints.length + 1,
      itemBuilder: (context, index) {
        if (index < waypoints.length) {
          return _WaypointSummary(
            key: ValueKey(waypoints[index].id),
            index: index,
            onTap: () => onWaypointTap(waypoints[index].id),
            data: waypoints[index],
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton(
              onPressed: () {
                db.createWaypoint(
                  tourId,
                  Waypoint(
                    name: "New waypoint",
                    desc: "",
                    lat: 0,
                    lng: 0,
                    narrationPath: null,
                  ),
                );
              },
              child: const Text("Create Waypoint"),
            ),
          );
        }
      },
    );
  }
}

class _WaypointSummary extends StatefulWidget {
  const _WaypointSummary({
    Key? key,
    required this.index,
    required this.data,
    required this.onTap,
  }) : super(key: key);

  final int index;
  final PointSummary data;
  final void Function() onTap;

  @override
  State<_WaypointSummary> createState() => _WaypointSummaryState();
}

class _WaypointSummaryState extends State<_WaypointSummary> {
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.data.id),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        focusColor: const Color(0x10000088),
        highlightColor: const Color(0x08000088),
        hoverColor: const Color(0x08000088),
        splashColor: const Color(0x08000088),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                "${widget.index + 1}.",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4.0),
              Text(
                widget.data.name!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _Coordinate(widget.data.lat, widget.data.lng),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Coordinate extends StatelessWidget {
  _Coordinate(
    double lat,
    double lng, {
    Key? key,
  })  : _formattedValue = _formatValue(lat, lng),
        super(key: key);

  final String _formattedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCCCCFF),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0,
        ),
        child: Text(
          _formattedValue,
          style: GoogleFonts.robotoMono(),
        ),
      ),
    );
  }

  static final _latFormat = NumberFormat("#0.000000");
  static final _lngFormat = NumberFormat("##0.000000");
  static String _formatValue(double lat, double lng) {
    var a = _latFormat.format(lat);
    var b = _lngFormat.format(lng);
    return "$a, $b";
  }
}
