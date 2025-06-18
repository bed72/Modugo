import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

extension ContextStateExtension on BuildContext {
  GoRouter get goRouter => GoRouter.of(this);

  GoRouterState get state => GoRouterState.of(this);

  String? get path => state.path;

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

  T? getExtra<T>() => state.extra as T?;

  T argumentsOrThrow<T>() {
    final extra = state.extra;
    if (extra is T) return extra;
    throw Exception('Expected extra of type $T, got: $extra');
  }

  bool get isInitialRoute => state.matchedLocation == '/';

  bool isCurrentRoute(String name) => state.name == name;
}
