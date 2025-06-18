import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/paths/extract.dart';
import 'package:modugo/src/routes/paths/regexp.dart';

extension ContextMatchExtension on BuildContext {
  bool isKnownPath(String path) =>
      _matchPath(path, GoRouter.of(this).configuration.routes);

  bool isKnownRouteName(String name) =>
      _matchName(name, GoRouter.of(this).configuration.routes);

  GoRoute? matchingRoute(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = GoRouter.of(this).configuration.routes;
    return _findMatchingRoute(path, routes);
  }

  Map<String, String>? matchParams(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = GoRouter.of(this).configuration.routes;
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
