import 'package:flutter/material.dart';

enum TypeTransition {
  fade,
  scale,
  slideUp,
  rotation,
  slideDown,
  slideLeft,
  slideRight,
}

final class Transition {
  Transition._();
  static Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  builder({required TypeTransition type, required void Function() config}) => (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    config();

    return switch (type) {
      TypeTransition.slideUp => SlideTransition(
        position: Tween(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      TypeTransition.slideDown => SlideTransition(
        position: Tween(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      TypeTransition.slideLeft => SlideTransition(
        position: Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      TypeTransition.slideRight => SlideTransition(
        position: Tween(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      TypeTransition.fade => FadeTransition(opacity: animation, child: child),
      TypeTransition.scale => ScaleTransition(scale: animation, child: child),
      TypeTransition.rotation => RotationTransition(
        turns: animation,
        child: child,
      ),
    };
  };
}
