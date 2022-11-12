import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '/db/db.dart';
import '/widgets/map_icon.dart';

class PoiMap extends StatelessWidget {
  const PoiMap({super.key, required this.pois});

  final List<PointSummary> pois;

  @override
  Widget build(BuildContext context) {
    var db = context.watch<Future<OtbDatabase>>();

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
          userAgentPackageName: "org.opentourbuilder.builder",
        ),
        DragMarkers(
          markers: [
            for (var poi in pois.asMap().entries)
              DragMarker(
                point: LatLng(poi.value.lat, poi.value.lng),
                width: 100,
                height: 100,
                preservePosition: false,
                onDragEnd: (details, point) async {
                  (await db).poi(poi.value.id).then(
                    (loadedPoi) {
                      loadedPoi?.data?.lat = point.latitude;
                      loadedPoi?.data?.lng = point.longitude;
                      loadedPoi?.dispose();
                    },
                  );
                },
                builder: (context) => const MapIcon(
                  child: Center(
                    child: Icon(
                      Icons.local_restaurant,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
