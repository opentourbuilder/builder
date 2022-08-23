import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../db/db.dart';

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
                      _WaypointsEditor(
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
            child: _TourMap(
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

class _TourMap extends StatelessWidget {
  const _TourMap({
    Key? key,
    required this.waypoints,
    required this.tourId,
  }) : super(key: key);

  final List<PointSummary> waypoints;
  final Uuid tourId;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        onTap: (tapPosition, point) {
          db.loadWaypoint(waypoints[0].id).then((value) {
            value!.lat = point.latitude;
            value.lng = point.longitude;
            db.updateWaypoint(tourId, waypoints[0].id, value);
          });
        },
        center: LatLng(37.09024, -95.712891),
        zoom: 4,
        maxZoom: 18,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'org.evresi.builder',
        ),
        MarkerLayerOptions(
          markers: [
            for (var waypoint in waypoints)
              Marker(
                point: LatLng(waypoint.lat, waypoint.lng),
                width: 20,
                height: 20,
                builder: (context) => const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ],
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: null,
        ),
      ],
    );
  }
}

class _WaypointsEditor extends StatefulWidget {
  const _WaypointsEditor({
    Key? key,
    required this.tourId,
    required this.waypoints,
  }) : super(key: key);

  final Uuid tourId;
  final List<PointSummary> waypoints;

  @override
  State<StatefulWidget> createState() => _WaypointsEditorState();
}

class _WaypointsEditorState extends State<_WaypointsEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
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
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.waypoints.length,
            itemBuilder: (context, index) {
              return _WaypointSummary(
                index: index,
                data: widget.waypoints[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WaypointSummary extends StatefulWidget {
  const _WaypointSummary({
    Key? key,
    required this.index,
    required this.data,
  }) : super(key: key);

  final int index;
  final PointSummary data;

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
        onTap: () {},
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
