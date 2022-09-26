import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:latlong2/latlong.dart';

import '/db/db.dart' as db;
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

  StreamSubscription<db.Event>? _eventsSubscription;

  List<db.PointSummary> _waypoints = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _eventsSubscription = db.instance.events.listen(_onEvent);
    db.instance.requestEvent(const db.WaypointsEventDescriptor());
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _onEvent(db.Event event) {
    if (event.desc == const db.WaypointsEventDescriptor()) {
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
        DragMarkers(
          markers: [
            for (var waypoint in _waypoints.asMap().entries)
              DragMarker(
                point: LatLng(waypoint.value.lat, waypoint.value.lng),
                width: 40,
                height: 40,
                preservePosition: false,
                onDragEnd: (details, point) {
                  db.instance.waypoint(waypoint.value.id).then(
                    (loadedWaypoint) {
                      loadedWaypoint?.data?.lat = point.latitude;
                      loadedWaypoint?.data?.lng = point.longitude;
                      loadedWaypoint?.dispose();
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
