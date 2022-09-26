import 'dart:math';

import 'package:flutter/material.dart';

import '/db/db.dart' as db;
import '/db/models/point.dart';
import '/geocoder.dart';
import 'modal.dart';

const _poiEditorInputDecoration = InputDecoration(
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  hoverColor: Color(0xFFFFFFFF),
);

class LocationField<O extends db.DbObject<DataAccessor, Id, Data>,
    DataAccessor extends DbPointAccessor, Id, Data> extends StatefulWidget {
  const LocationField({
    super.key,
    required this.point,
  });

  final O? point;

  @override
  State<StatefulWidget> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  final TextEditingController latController = TextEditingController();
  String prevLatText = "";
  final TextEditingController lngController = TextEditingController();
  String prevLngText = "";
  bool latBad = false;
  bool lngBad = false;
  double lat = 0;
  double lng = 0;

  @override
  void initState() {
    super.initState();

    latController.addListener(() {
      if (latController.text == prevLatText) return;
      final String text = latController.text.replaceAll(RegExp(r'[^\d.-]'), "");
      prevLatText = text;
      latController.value = latController.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset:
              min(latController.value.selection.baseOffset, text.length),
          extentOffset:
              min(latController.value.selection.extentOffset, text.length),
        ),
      );

      double? newLat = double.tryParse(text);
      setState(() {
        if (newLat != null && newLat >= -90 && newLat <= 90) {
          lat = newLat;
          widget.point?.data?.lat = newLat;
          latBad = false;
        } else {
          latBad = true;
        }
      });
    });
    lngController.addListener(() {
      if (lngController.text == prevLngText) return;
      final String text = lngController.text.replaceAll(RegExp(r'[^\d.-]'), "");
      prevLngText = text;
      lngController.value = lngController.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset:
              min(lngController.value.selection.baseOffset, text.length),
          extentOffset:
              min(lngController.value.selection.extentOffset, text.length),
        ),
      );

      double? newLng = double.tryParse(text);
      setState(() {
        if (newLng != null && newLng >= -180 && newLng <= 180) {
          lng = newLng;
          widget.point?.data?.lng = newLng;
          lngBad = false;
        } else {
          lngBad = true;
        }
      });
    });

    lat = widget.point?.data?.lat ?? 0;
    lng = widget.point?.data?.lng ?? 0;
    latController.text = '$lat';
    lngController.text = '$lng';
  }

  @override
  void didUpdateWidget(covariant LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.point != widget.point || widget.point?.changed == true) {
      lat = widget.point?.data?.lat ?? 0;
      lng = widget.point?.data?.lng ?? 0;
      latController.text = '$lat';
      lngController.text = '$lng';
    }
  }

  @override
  void dispose() {
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            decoration: _poiEditorInputDecoration.copyWith(
              labelText: "Latitude",
              errorText: latBad ? "Must be a number between -90 and 90" : null,
              errorMaxLines: 2,
            ),
            controller: latController,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextField(
            decoration: _poiEditorInputDecoration.copyWith(
              labelText: "Longitude",
              errorText:
                  lngBad ? "Must be a number between -180 and 180" : null,
              errorMaxLines: 2,
            ),
            controller: lngController,
          ),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: () async {
            var place = await Navigator.of(context, rootNavigator: true)
                .push(AddressModalRoute()) as Place?;

            if (place != null) {
              setState(() {
                lat = place.lat;
                widget.point?.data?.lat = place.lat;
                lng = place.lng;
                widget.point?.data?.lng = place.lng;
                latController.text = '$lat';
                lngController.text = '$lng';
              });
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.secondary),
          ),
          child: const Icon(Icons.pin_drop),
        ),
      ],
    );
  }
}

class AddressModalRoute extends ModalRoute {
  @override
  Color? get barrierColor => const Color.fromARGB(64, 0, 0, 0);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      const AddressModal();
}

class AddressModal extends StatefulWidget {
  const AddressModal({super.key});

  @override
  State<StatefulWidget> createState() => _AddressModalState();
}

class _AddressModalState extends State<AddressModal> {
  String address = "";
  Future<List<Place>> results = Future.value([]);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Center(
        child: SizedBox(
          width: 500,
          child: Modal(
            title: const Text("Set Location to Street Address"),
            child: Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 16.0, left: 16.0, right: 16.0),
                    child: TextField(
                      onChanged: (value) {
                        address = value;
                      },
                      onSubmitted: (value) {
                        setState(() {
                          results = GeocodioService.instance.then(
                              (geocoder) => geocoder.forwardGeocode(address));
                        });
                      },
                      decoration: _poiEditorInputDecoration.copyWith(
                        labelText: "Street Address",
                        hintText:
                            "Type a street address here and press Enter...",
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Place>>(
                      future: results,
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return Container();
                          case ConnectionState.waiting:
                            return const Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          case ConnectionState.active:
                          case ConnectionState.done:
                            if (snapshot.data != null) {
                              return ListView(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                  top: 8.0,
                                ),
                                children: [
                                  for (var place in snapshot.data!)
                                    Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        focusColor: const Color(0x168888FF),
                                        highlightColor: const Color(0x128888FF),
                                        hoverColor: const Color(0x128888FF),
                                        splashColor: const Color(0x128888FF),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        onTap: () {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop(place);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(place.formattedAddress),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              return const Text("Error");
                            }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
