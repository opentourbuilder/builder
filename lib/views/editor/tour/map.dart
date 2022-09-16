import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '/db/db.dart' as db;
import '/models/editor/tour.dart';
import '/router.dart';

class TourMap extends StatefulWidget {
  const TourMap({
    Key? key,
    required this.tourId,
  }) : super(key: key);

  final db.Uuid tourId;

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
                width: 30,
                height: 30,
                preservePosition: false,
                onDragEnd: (details, point) {
                  db.instance.waypoint(widget.tourId, waypoint.value.id).then(
                    (loadedWaypoint) {
                      loadedWaypoint?.lat = point.latitude;
                      loadedWaypoint?.lng = point.longitude;
                    },
                  );
                },
                builder: (context) => _TourMapIcon(
                  index: waypoint.key,
                  onPressed: () {},
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TourMapIcon extends StatelessWidget {
  const _TourMapIcon({Key? key, required this.onPressed, required this.index})
      : super(key: key);

  final void Function() onPressed;
  final int index;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      shape: const CircleBorder(
        side: BorderSide(color: Colors.black, width: 2.5),
      ),
      fillColor: const Color.fromARGB(255, 255, 73, 73),
      onPressed: onPressed,
      child: Text(
        '${index + 1}',
        style: Theme.of(context).textTheme.button?.copyWith(
              fontSize: 14.0,
              color: Colors.white,
            ),
      ),
    );
  }
}
