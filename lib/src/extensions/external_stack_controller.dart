// coverage:ignore-file

import 'package:modugo/modugo.dart';

/// Extension on [ModugoStackController] to provide convenient navigation
/// methods integrated with Modugo.
///
/// These helpers offer stack-aware navigation using `go`, `push`, and `pop`,
/// automatically storing and restoring the route history independently
/// from `GoRouter`'s internal navigator stack.
extension ExternalStackControllerExtension on ModugoStackController {
  /// Pushes the current route to the stack and navigates to the new [path]
  /// using [Modugo.routerConfig.go].
  ///
  /// You can provide an optional [extra] map to pass data along the route.
  ///
  /// Example:
  /// ```dart
  /// ExternalStackController.instance.goWithStack('/profile', extra: {'from': 'home'});
  /// ```
  void goWithStack(String path, {Map<String, dynamic>? extra}) {
    final current = Modugo.routerConfig.state.uri.toString();
    push(current);

    Modugo.routerConfig.go(
      path,
      extra: {
        ModugoStackController.instance.path: path,
        ModugoStackController.instance.isExternalStackControl: true,
        ...?extra,
      },
    );
  }

  /// Pushes the current route to the stack and performs a [push] navigation
  /// to the provided [path] using [Modugo.routerConfig.push].
  ///
  /// Optionally, you may pass a [extra] map to carry data with the navigation.
  ///
  /// Example:
  /// ```dart
  /// await ExternalStackController.instance.pushWithStack('/cart', extra: {'productId': '123'});
  /// ```
  Future<void> pushWithStack(String path, {Map<String, dynamic>? extra}) async {
    final current = Modugo.routerConfig.state.uri.toString();
    push(current);

    await Modugo.routerConfig.push(
      path,
      extra: {
        ModugoStackController.instance.path: path,
        ModugoStackController.instance.isExternalStackControl: true,
        ...?extra,
      },
    );
  }

  /// Pops the last saved route from the stack and navigates back to it using
  /// [Modugo.routerConfig.go]. If the stack is empty, performs a standard pop.
  ///
  /// Example:
  /// ```dart
  /// ExternalStackController.instance.popWithStack();
  /// ```
  void popWithStack() {
    final last = pop();

    last != null ? Modugo.routerConfig.go(last) : Modugo.routerConfig.pop();
  }

  /// Checks whether the controller has any routes available to pop.
  ///
  /// This is equivalent to [canPop] and can be used for readability.
  ///
  /// Example:
  /// ```dart
  /// if (ExternalStackController.instance.hasBackstack) {
  ///   ExternalStackController.instance.popWithStack();
  /// }
  /// ```
  bool get hasBackstack => canPop;
}
