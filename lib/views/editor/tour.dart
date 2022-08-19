import 'package:flutter/material.dart';

import '../../db/db.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({Key? key, required this.tourId}) : super(key: key);

  final Uuid tourId;

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
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
    Widget inner;
    if (_tour == null) {
      inner = const Text("Error: tour not found!");
    } else {
      var tour = _tour!;
      inner = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController(text: tour.name),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: "Title",
              ),
            ),
          ),
          const Divider(
            height: 1.0,
            thickness: 1.0,
          ),
        ],
      );
    }

    return Stack(
      children: [
        if (!_tourLoaded) const Center(child: CircularProgressIndicator()),
        AnimatedOpacity(
          opacity: _tourLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 100),
          child: inner,
        ),
      ],
    );
  }
}
