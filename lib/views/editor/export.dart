import 'package:flutter/material.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({Key? key, required this.finished}) : super(key: key);

  final bool finished;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 28,
          color: const Color.fromARGB(255, 94, 99, 124),
        );
    return Material(
      color: const Color.fromARGB(255, 249, 250, 255),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(finished ? "Finished export." : "Exporting...", style: style),
          ],
        ),
      ),
    );
  }
}
