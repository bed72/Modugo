import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:modugo/src/injector.dart';

extension BindContextExtension on BuildContext {
  T read<T>() => Bind.get<T>();

  GoRouter get goRouter => GoRouter.of(this);

  GoRouterState get state => GoRouterState.of(this);

  String? get path => state.path;

  T? getExtra<T>() => state.extra as T?;

  bool isCurrentRoute(String name) => state.name == name;

  bool get isInitialRoute => state.matchedLocation == '/';

  List<String> get locationSegments => state.uri.pathSegments;

  String? getPathParam(String param) => state.pathParameters[param];

  String? getStringQueryParam(String key) => state.uri.queryParameters[key];

  int? getIntQueryParam(String key) =>
      int.tryParse(state.uri.queryParameters[key] ?? '');

  bool? getBoolQueryParam(String key) {
    final value = state.uri.queryParameters[key];
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  T argumentsOrThrow<T>() {
    final extra = state.extra;
    if (extra is T) return extra;
    throw Exception('Expected extra of type $T, got: $extra');
  }

  bool isKnownPath(String path) =>
      _matchPath(path, GoRouter.of(this).configuration.routes);

  bool isKnownRouteName(String name) =>
      _matchName(name, GoRouter.of(this).configuration.routes);

  void reload() {
    goRouter.go(state.uri.toString());
  }

  bool canPop() => goRouter.canPop();

  void go(String location, {Object? extra}) =>
      goRouter.go(location, extra: extra);

  void pop<T extends Object?>([T? result]) => goRouter.pop(result);

  void replace(String location, {Object? extra}) =>
      goRouter.replace<Object?>(location, extra: extra);

  void pushReplacement(String location, {Object? extra}) =>
      goRouter.pushReplacement(location, extra: extra);

  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => goRouter.replaceNamed<Object?>(
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

  void pushReplacementNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => goRouter.pushReplacementNamed(
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

  bool _matchPath(String path, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute && route.path == path) return true;
      if (route is ShellRoute) {
        if (_matchPath(path, route.routes)) return true;
      }
    }
    return false;
  }

  bool _matchName(String name, List<RouteBase> routes) {
    for (final route in routes) {
      if (route is GoRoute && route.name == name) return true;
      if (route is ShellRoute) {
        if (_matchName(name, route.routes)) return true;
      }
    }
    return false;
  }
}
