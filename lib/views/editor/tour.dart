import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/db.dart';

class TourEditor extends StatefulWidget {
  const TourEditor({Key? key, required this.tourId}) : super(key: key);

  final Uuid tourId;

  @override
  State<TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<TourEditor> {
  Timer? _saveTimer;
  Tour? _tour;
  bool _tourLoaded = false;

  @override
  void initState() {
    super.initState();
    db.loadTour(widget.tourId).then((tour) {
      setState(() {
        _tour = tour;
        _tourLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_tourLoaded) return const Center(child: CircularProgressIndicator());
    if (_tour == null) return const Text("Error: tour not found!");

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: FloatingLabelAlignment.start,
      isDense: true,
      labelText: "Title",
    );

    var tour = _tour!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: TextEditingController(text: tour.name),
            onChanged: (value) {
              tour.name = value;
              _updateSaveTimer();
            },
            decoration: inputDecoration,
          ),
        ),
        const Divider(
          height: 1.0,
          thickness: 1.0,
        ),
      ],
    );
  }

  void _updateSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      db.updateTour(widget.tourId, _tour!);
    });
  }
}
