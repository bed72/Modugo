import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

import 'package:path_to_regexp/path_to_regexp.dart';

/// Extension on [BuildContext] that provides advanced route matching utilities.
///
/// These methods allow you to:
/// - verify if a route path or name is registered
/// - find the corresponding [GoRoute] for a given location
/// - extract route parameters from a path
///
/// This is particularly useful for dynamic routing, conditional navigation,
/// link validation, and debugging route configurations.
///
/// Example:
/// ```dart
/// final isValid = context.isKnownPath('/settings');
/// final isNamed = context.isKnownRouteName('profile');
///
/// final matchedRoute = context.matchingRoute('/user/42');
/// final params = context.matchParams('/user/42');
/// final userId = params?['id'];
/// ```
extension ContextMatchExtension on BuildContext {
  GoRouter get _goRouter => GoRouter.of(this);

  /// Provides access to the current [GoRouterState].
  ///
  /// This getter exposes the internal [GoRouter.state] instance,
  /// which holds information about the active route such as:
  /// - the current location (`location`)
  /// - path parameters (`pathParameters`)
  /// - query parameters (`queryParameters`)
  /// - route name (`name`)
  /// - and any extra data passed during navigation (`extra`)
  ///
  /// ### Example
  /// ```dart
  /// final currentPath = router.state.location;
  /// final id = router.state.pathParameters['id'];
  /// ```
  ///
  /// This is particularly useful inside navigation or route-related
  /// utilities where you need to inspect the current navigation state.
  GoRouterState get state => _goRouter.state;

  /// Checks whether the given [path] matches any route currently registered in the app.
  ///
  /// This is useful for validating user inputs or links before navigation,
  /// ensuring the path corresponds to a known route defined in [GoRouter.configuration].
  ///
  /// Example:
  /// ```dart
  /// final isValid = context.isKnownPath('/settings');
  /// if (isValid) {
  ///   context.go('/settings');
  /// } else {
  ///   showDialog(...); // show error
  /// }
  /// ```
  bool isKnownPath(String path) =>
      _matchPath(path, _goRouter.configuration.routes);

  /// Checks whether the given [name] matches any named route registered in the current [GoRouter] configuration.
  ///
  /// Useful for conditional navigation or validating whether a route name
  /// exists before attempting to navigate.
  ///
  /// Example:
  /// ```dart
  /// if (context.isKnownRouteName('profile')) {
  ///   context.goNamed('profile');
  /// } else {
  ///   debugPrint('Route not found');
  /// }
  /// ```
  ///
  /// This method performs a recursive search over all registered [RouteBase] objects.
  bool isKnownRouteName(String name) =>
      _matchName(name, _goRouter.configuration.routes);

  /// Finds the first [GoRoute] that matches the given [location] string.
  ///
  /// This parses the [location] as a URI and searches for a matching route
  /// based on the path segment, using the current [GoRouter] configuration.
  ///
  /// Returns `null` if no match is found.
  ///
  /// Example:
  /// ```dart
  /// final route = context.matchingRoute('/profile/settings');
  /// if (route != null) {
  ///   debugPrint('Matched route: ${route.name}');
  /// } else {
  ///   debugPrint('No route found for path');
  /// }
  /// ```
  GoRoute? matchingRoute(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = _goRouter.configuration.routes;
    return _findMatchingRoute(path, routes);
  }

  /// Matches the given [location] against the configured GoRouter routes
  /// and extracts the path parameters if a match is found.
  ///
  /// This is useful for manually parsing dynamic segments from a URL,
  /// especially outside of the context of a `BuildContext` or `GoRouterState`.
  ///
  /// For example, if a route is defined as `/user/:id`, calling:
  ///
  /// ```dart
  /// matchParams('/user/42');
  /// ```
  ///
  /// will return:
  ///
  /// ```dart
  /// {'id': '42'}
  /// ```
  ///
  /// Returns a [Map] of path parameters if a route matches,
  /// or `null` if no match is found.
  ///
  /// Throws [FormatException] if the [location] is not a valid URI.
  Map<String, String>? matchParams(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = _goRouter.configuration.routes;
    return _extractParams(path, routes);
  }

  RegExp _buildRegExp(String pattern) {
    final keys = <String>[];
    return pathToRegExp(pattern, parameters: keys);
  }

  GoRoute? _findMatchingRoute(String path, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute) {
        final regExp = _buildRegExp(route.path);
        if (regExp.hasMatch(path)) return route;
      } else if (route is ShellRouteBase) {
        final match = _findMatchingRoute(path, route.routes);
        if (match != null) return match;
      }
    }
    return null;
  }

  Map<String, String>? _extractParams(String path, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute) {
        final parameters = <String>[];
        final regExp = pathToRegExp(route.path, parameters: parameters);
        final match = regExp.matchAsPrefix(path);
        if (match != null) return extract(parameters, match);
      } else if (route is ShellRouteBase) {
        final nested = _extractParams(path, route.routes);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  bool _matchPath(String path, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute && route.path == path) return true;
      if (route is ShellRouteBase) {
        if (_matchPath(path, route.routes)) return true;
      }
    }
    return false;
  }

  bool _matchName(String name, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute && route.name == name) return true;
      if (route is ShellRouteBase) {
        if (_matchName(name, route.routes)) return true;
      }
    }
    return false;
  }
}
