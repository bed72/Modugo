// coverage:ignore-file

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/paths/regexp.dart';

/// Extension on [BuildContext] that provides convenient navigation helpers
/// using [GoRouter].
///
/// This extension simplifies navigation by exposing commonly used methods such as:
/// - [go], [goNamed] for direct route changes
/// - [push], [pushNamed], [replace], etc. for stack-based navigation
/// - [pop], [canPop], [reload] for back navigation and route control
///
/// These methods are thin wrappers around [GoRouter] operations, making it easier
/// to navigate within your widget tree without manually calling `GoRouter.of(context)`.
///
/// Example:
/// ```dart
/// context.go('/home');
/// context.pushNamed('product', pathParameters: {'id': '42'});
/// if (context.canPop()) context.pop();
/// context.reload(); // reloads current route
/// ```
extension ContextNavigationExtension on BuildContext {
  /// Provides direct access to the current [GoRouter] instance from the [BuildContext].
  ///
  /// This is a shorthand for `GoRouter.of(context)` and is useful when you need
  /// to access router-level information like configuration, current location,
  /// or programmatically navigate using `go()`, `push()`, etc.
  ///
  /// Example:
  /// ```dart
  /// final location = context.goRouter.location;
  /// final canPop = context.goRouter.canPop();
  /// context.goRouter.go('/dashboard');
  /// ```
  GoRouter get goRouter => GoRouter.of(this);

  /// Forces a reload of the current route by navigating to the same URI again.
  ///
  /// This is useful when you want to refresh the state or UI associated
  /// with the current route without changing the location.
  ///
  /// It performs a full navigation cycle using the current URI.
  ///
  /// Example:
  /// ```dart
  /// // Refresh the current screen
  /// context.reload();
  /// ```
  ///
  /// Internally, this is equivalent to:
  /// ```dart
  /// context.go(context.state.uri.toString());
  /// ```
  void reload() {
    goRouter.go(GoRouterState.of(this).uri.toString());
  }

  /// Returns `true` if the navigation stack can be popped (i.e. there's a previous route).
  ///
  /// This is useful to determine whether a `pop()` action would have any effect,
  /// particularly in nested navigators or when building custom back buttons.
  ///
  /// Example:
  /// ```dart
  /// if (context.canPop()) {
  ///   context.pop();
  /// } else {
  ///   Navigator.of(context).maybePop(); // or handle fallback
  /// }
  /// ```
  ///
  /// This uses [GoRouter.canPop] under the hood.
  bool canPop() => goRouter.canPop();

  /// Checks whether the given [location] is a valid route path that can be pushed.
  ///
  /// This parses the provided [location] as a URI and verifies if the `path`
  /// segment matches any route registered in the current [GoRouter] configuration.
  ///
  /// It’s helpful for validating navigation targets before calling [go], [push], etc.
  ///
  /// Example:
  /// ```dart
  /// if (context.canPush('/settings')) {
  ///   context.go('/settings');
  /// } else {
  ///   debugPrint('Invalid path: /settings');
  /// }
  /// ```
  ///
  /// Note: Only checks for path-based matches, not query or extra data.
  bool canPush(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = goRouter.configuration.routes;

    return _matchesPath(path, routes);
  }

  /// Navigates to the given [location] using the current [GoRouter].
  ///
  /// Equivalent to calling `GoRouter.of(context).go(...)`.
  ///
  /// Example:
  /// ```dart
  /// context.go('/dashboard');
  /// ```
  void go(String location, {Object? extra}) =>
      goRouter.go(location, extra: extra);

  /// Pops the current route off the navigation stack.
  ///
  /// Optionally returns a [result] to the previous route.
  ///
  /// Example:
  /// ```dart
  /// context.pop();                // just pop
  /// context.pop('my-result');     // pop with result
  /// ```
  void pop<T extends Object?>([T? result]) => goRouter.pop<T>(result);

  /// Replaces the current route with a new one at [location].
  ///
  /// Example:
  /// ```dart
  /// context.replace('/settings');
  /// ```
  Future<T?> replace<T>(String location, {Object? extra}) =>
      goRouter.replace<T?>(location, extra: extra);

  /// Replaces the current route with a new one and returns a result when popped.
  ///
  /// Example:
  /// ```dart
  /// final result = await context.pushReplacement('/checkout');
  /// ```
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) => goRouter.pushReplacement<T>(location, extra: extra);

  /// Pushes a new route onto the stack and returns a result when it is popped.
  ///
  /// Example:
  /// ```dart
  /// final result = await context.push('/product/42');
  /// ```
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async =>
      goRouter.push<T>(location, extra: extra);

  /// Replaces the current route with a named route.
  ///
  /// Example:
  /// ```dart
  /// context.replaceNamed('settings');
  /// ```
  Future<T?> replaceNamed<T>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => goRouter.replaceNamed<T?>(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  /// Pushes a new named route and returns a result when it is popped.
  ///
  /// Example:
  /// ```dart
  /// final result = await context.pushNamed(
  ///   'product',
  ///   pathParameters: {'id': '42'},
  /// );
  /// ```
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => goRouter.pushNamed<T>(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  /// Replaces the current route with a named one and returns a result when popped.
  ///
  /// Example:
  /// ```dart
  /// final result = await context.pushReplacementNamed(
  ///   'checkout',
  ///   pathParameters: {'step': '2'},
  /// );
  /// ```
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => goRouter.pushReplacementNamed<T>(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  /// Navigates to a named route using the given parameters.
  ///
  /// Example:
  /// ```dart
  /// context.goNamed(
  ///   'profile',
  ///   pathParameters: {'userId': '123'},
  ///   queryParameters: {'tab': 'info'},
  /// );
  /// ```
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) => goRouter.goNamed(
    name,
    extra: extra,
    fragment: fragment,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  RegExp _buildRegExp(String pattern) {
    final keys = <String>[];
    return pathToRegExp(pattern, parameters: keys);
  }

  bool _matchesPath(String path, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute) {
        final regExp = _buildRegExp(route.path);
        if (regExp.hasMatch(path)) return true;
      } else if (route is ShellRouteBase) {
        if (_matchesPath(path, route.routes)) return true;
      }
    }
    return false;
  }
}
