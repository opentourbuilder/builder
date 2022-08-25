import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '/db/db.dart';

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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FlutterMap(
      options: MapOptions(
        onTap: (tapPosition, point) {
          db.loadWaypoint(widget.waypoints[0].id).then((value) {
            value!.lat = point.latitude;
            value.lng = point.longitude;
            db.updateWaypoint(widget.tourId, widget.waypoints[0].id, value);
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
