import 'package:flutter/material.dart';

class EvresiPageRoute<T> extends PageRoute<T> {
  EvresiPageRoute(this.builder);

  Widget Function(BuildContext) builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool get offstage => false;
}
