import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '/db/db.dart';
import '/models/editor/tour.dart';
import '/router.dart';

class TourMap extends StatefulWidget {
  const TourMap({
    Key? key,
    required this.waypoints,
    required this.tourId,
  }) : super(key: key);

  final List<PointSummary> waypoints;
  final Uuid tourId;

  @override
  State<TourMap> createState() => _TourMapState();
}

class _TourMapState extends State<TourMap> with AutomaticKeepAliveClientMixin {
  ValhallaRouter router = ValhallaRouter();
  List<LatLng>? route;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (widget.waypoints.length >= 2) {
      router
          .route(widget.waypoints.map((w) => LatLng(w.lat, w.lng)))
          .then((value) => setState(() => route = value));
    }
  }

  @override
  void didUpdateWidget(TourMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.waypoints.length >= 2) {
      router
          .route(widget.waypoints.map((w) => LatLng(w.lat, w.lng)))
          .then((value) => setState(() => route = value));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var tourEditorModel = context.watch<TourEditorModel>();

    return FlutterMap(
      options: MapOptions(
        onTap: (tapPosition, point) {
          var selectedWaypoint = tourEditorModel.selectedWaypoint;
          if (selectedWaypoint != null) {
            db.loadWaypoint(selectedWaypoint).then((value) {
              value!.lat = point.latitude;
              value.lng = point.longitude;
              db.updateWaypoint(widget.tourId, selectedWaypoint, value);
            });
          }
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
            for (var waypoint in widget.waypoints)
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
        PolylineLayerOptions(
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
