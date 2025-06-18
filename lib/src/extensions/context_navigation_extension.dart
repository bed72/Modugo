// coverage:ignore-file

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/paths/regexp.dart';

extension ContextNavigationExtension on BuildContext {
  GoRouter get goRouter => GoRouter.of(this);

  GoRouterState get state => GoRouterState.of(this);

  void reload() {
    goRouter.go(state.uri.toString());
  }

  bool canPop() => goRouter.canPop();

  bool canPush(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;
    final routes = goRouter.configuration.routes;

    return _matchesPath(path, routes);
  }

  void go(String location, {Object? extra}) =>
      goRouter.go(location, extra: extra);

  void pop<T extends Object?>([T? result]) => goRouter.pop<T>(result);

  Future<T?> replace<T>(String location, {Object? extra}) =>
      goRouter.replace<T?>(location, extra: extra);

  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) => goRouter.pushReplacement<T>(location, extra: extra);

  Future<T?> push<T extends Object?>(String location, {Object? extra}) async =>
      goRouter.push<T>(location, extra: extra);

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
