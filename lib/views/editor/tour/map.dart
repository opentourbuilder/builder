import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:latlong2/latlong.dart';

import '/db/db.dart';
import '/router.dart';
import '/widgets/map_icon.dart';

class TourMap extends StatefulWidget {
  const TourMap({super.key});

  @override
  State<TourMap> createState() => _TourMapState();
}

class _TourMapState extends State<TourMap> with AutomaticKeepAliveClientMixin {
  ValhallaRouter router = ValhallaRouter();
  List<LatLng>? route;

  StreamSubscription<Event>? _eventsSubscription;

  List<PointSummary> _waypoints = [];

  @override
  bool get wantKeepAlive => true;

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

      router
          .route(_waypoints.map((w) => LatLng(w.lat, w.lng)))
          .then((value) => setState(() => route = value));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var db = context.watch<Future<EvresiDatabase>>();

    return FlutterMap(
      options: MapOptions(
        center: LatLng(37.09024, -95.712891),
        zoom: 4,
        maxZoom: 18,
      ),
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: null,
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "org.evresi.builder",
        ),
        PolylineLayer(
          polylineCulling: false,
          polylines: [
            if (route != null)
              Polyline(
                points: route!,
                color: Colors.red,
                borderColor: Colors.black,
                strokeWidth: 3.5,
              ),
          ],
        ),
        CircleLayer(
          circles: [
            for (var waypoint in _waypoints.asMap().entries)
              if (waypoint.value.triggerRadius != null)
                CircleMarker(
                  point: LatLng(waypoint.value.lat, waypoint.value.lng),
                  radius: waypoint.value.triggerRadius!,
                  color: const Color.fromARGB(97, 255, 76, 44),
                  useRadiusInMeter: true,
                ),
          ],
        ),
        DragMarkers(
          markers: [
            for (var waypoint in _waypoints.asMap().entries)
              DragMarker(
                point: LatLng(waypoint.value.lat, waypoint.value.lng),
                width: 40,
                height: 40,
                preservePosition: false,
                onDragEnd: (details, point) async {
                  (await db).waypoint(waypoint.value.id).then(
                    (loadedWaypoint) {
                      if (loadedWaypoint == null) return;
                      loadedWaypoint.data?.lat = point.latitude;
                      loadedWaypoint.data?.lng = point.longitude;
                      loadedWaypoint.dispose();
                    },
                  );
                },
                builder: (context) => MapIcon(
                  child: Center(
                    child: Text(
                      '${waypoint.key + 1}',
                      style: Theme.of(context).textTheme.button?.copyWith(
                            fontSize: 14.0,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  onPressed: () {},
                ),
              ),
          ],
        ),
      ],
    );
  }
}
