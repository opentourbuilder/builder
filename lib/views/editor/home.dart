import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 20,
          color: const Color.fromARGB(255, 94, 99, 124),
        );
    return Material(
      color: const Color.fromARGB(255, 249, 250, 255),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome to the OpenTourBuilder!", style: style),
            const SizedBox(height: 8.0),
            Text(
                "To get started, try creating a tour by clicking 'New Tour...' in the top bar above.",
                style: style),
          ],
        ),
      ),
    );
  }
}
