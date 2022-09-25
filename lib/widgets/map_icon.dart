import 'package:flutter/material.dart';

class MapIcon extends StatelessWidget {
  const MapIcon({super.key, this.onPressed, required this.child});

  final void Function()? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // transparent color to make it detected for dragging
      color: Colors.transparent,
      child: Center(
        child: Container(
          decoration: const ShapeDecoration(
            color: Color.fromARGB(255, 255, 73, 73),
            shape: CircleBorder(
              side: BorderSide(color: Colors.black, width: 2.5),
            ),
          ),
          width: 30,
          height: 30,
          child: child,
        ),
      ),
    );
  }
}
