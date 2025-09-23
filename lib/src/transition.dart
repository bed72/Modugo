import 'package:flutter/widgets.dart';

/// Defines the supported types of transition animations for page navigation.
///
/// These transitions are used when pushing new routes in Modugo,
/// allowing custom visual effects.
///
/// Available types:
/// - [fade] → cross-fade
/// - [scale] → zoom in
/// - [slideUp] → enters from bottom
/// - [slideDown] → enters from top
/// - [slideLeft] → enters from right
/// - [slideRight] → enters from left
/// - [rotation] → rotates in
enum TypeTransition {
  fade,
  scale,
  slideUp,
  rotation,
  slideDown,
  slideLeft,
  slideRight,
}

/// Utility class that provides animated transition builders for Modugo routes.
///
/// Use [Transition.builder] to retrieve a transition animation
/// that matches a given [TypeTransition] enum.
///
/// Each builder returns a [Widget Function(...)] compatible with [CustomTransitionPage].
///
/// Example:
/// ```dart
/// CustomTransitionPage(
///   child: MyPage(),
///   transitionsBuilder: Transition.builder(
///     type: TypeTransition.slideLeft,
///     config: () => debugPrint('Applying transition'),
///   ),
/// );
/// ```
final class Transition {
  /// Private constructor — this class is not meant to be instantiated.
  Transition._();

  /// Returns a transition builder for the given [type].
  ///
  /// The [config] function is executed before returning the builder, allowing
  /// logging or configuration side effects.
  ///
  /// Supported transitions:
  /// - slide (up, down, left, right)
  /// - fade
  /// - scale
  /// - rotation
  ///
  /// Example:
  /// ```dart
  /// final builder = Transition.builder(
  ///   type: TypeTransition.fade,
  ///   config: () => print('Using fade'),
  /// );
  /// ```
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
