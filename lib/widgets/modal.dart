import 'package:flutter/material.dart';

class Modal extends StatelessWidget {
  const Modal({
    super.key,
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        type: MaterialType.card,
        shadowColor: Theme.of(context).colorScheme.shadow,
        elevation: 4.0,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              type: MaterialType.card,
              elevation: 8.0,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8.0),
                  title,
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
            const Divider(
              height: 2.0,
              thickness: 2.0,
            ),
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
