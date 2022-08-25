import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/db/db.dart';

class WaypointList extends StatefulWidget {
  const WaypointList({
    Key? key,
    required this.tourId,
    required this.waypoints,
  }) : super(key: key);

  final Uuid tourId;
  final List<PointSummary> waypoints;

  @override
  State<StatefulWidget> createState() => _WaypointListState();
}

class _WaypointListState extends State<WaypointList> {
  Uuid? selectedWaypoint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: widget.waypoints.length + 1,
          itemBuilder: (context, index) {
            if (index < widget.waypoints.length) {
              return _WaypointSummary(
                key: ValueKey(widget.waypoints[index].id),
                index: index,
                onTap: () {
                  setState(() => selectedWaypoint = widget.waypoints[index].id);
                },
                data: widget.waypoints[index],
              );
            } else {
              return ElevatedButton(
                onPressed: () {
                  db.createWaypoint(
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
                child: const Text("Create Waypoint"),
              );
            }
          },
        ),
        if (selectedWaypoint != null)
          Text("selected ${selectedWaypoint?.bytes}"),
      ],
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
