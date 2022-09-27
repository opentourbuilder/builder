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
    return Material(
      type: MaterialType.card,
      shadowColor: Theme.of(context).colorScheme.shadow,
      elevation: 8.0,
      color: const Color.fromARGB(255, 245, 247, 255),
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            type: MaterialType.card,
            color: const Color.fromARGB(255, 234, 236, 255),
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
            height: 1.0,
            thickness: 1.0,
            color: Color.fromARGB(255, 211, 212, 229),
          ),
          child,
        ],
      ),
    );
  }
}
