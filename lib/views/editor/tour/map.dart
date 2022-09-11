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
        MarkerLayer(
          markers: [
            for (var waypoint in widget.waypoints.asMap().entries)
              Marker(
                point: LatLng(waypoint.value.lat, waypoint.value.lng),
                width: 30,
                height: 30,
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
