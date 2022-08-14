import 'package:flutter/material.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({Key? key, required this.tourId}) : super(key: key);

  final String tourId;

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  String? _tour;

  @override
  Widget build(BuildContext context) {
    if (_tour != null) {
      var tour = _tour!;

      return Column(
        children: [
          Text(tour),
        ],
      );
    } else {
      return const Text("Error: tour not found!");
    }
  }
}
