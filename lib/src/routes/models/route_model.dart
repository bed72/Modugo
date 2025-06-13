import 'package:flutter/material.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/utils/router_utils.dart';

@immutable
final class RouteModuleModel {
  final String name;
  final String route;
  final String child;
  final String module;
  final List<String>? params;
  final TypeTransition transition;

  const RouteModuleModel({
    required this.route,
    required this.child,
    required this.module,
    this.params,
    this.name = '',
    this.transition = TypeTransition.fade,
  });

  @override
  String toString() =>
      'RouteModuleModel(module: $module, child: $child, route: $route, params: $params)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModuleModel &&
          name == other.name &&
          route == other.route &&
          child == other.child &&
          module == other.module &&
          transition == other.transition &&
          runtimeType == other.runtimeType &&
          listEquals(params, other.params);

  @override
  int get hashCode =>
      name.hashCode ^
      route.hashCode ^
      child.hashCode ^
      module.hashCode ^
      (params == null ? 0 : Object.hashAll(params!)) ^
      transition.hashCode;

  String buildPath({
    List<String> params = const [],
    List<String> subParams = const [],
  }) {
    String paramPath = params.map((e) => '/$e').join('');
    String subParamPath = subParams.map((e) => '/$e').join('');
    int index = child.contains('/:') ? child.indexOf('/:') : child.length;

    return resolvePath(
      module + subParamPath + child.substring(0, index) + paramPath,
    );
  }

  static RouteModuleModel build({
    required String module,
    required String routeName,
    List<String> params = const [],
  }) {
    final sanitizedRouteName = routeName.replaceAll(RegExp(r'/+$'), '');

    final cleanRouteName = removeDuplicatedPrefix(module, sanitizedRouteName);

    final shouldAppendParams = !hasEmbeddedParams(cleanRouteName);
    final args = shouldAppendParams ? params.map((e) => ':$e').join('/') : '';
    final rawChild = '$cleanRouteName/${args.isNotEmpty ? args : ''}';
    final child = normalizePath(ensureLeadingSlash(rawChild));

    final rawRoute = '/$module/${cleanRouteName.isEmpty ? '' : cleanRouteName}';
    final route = normalizePath(rawRoute);

    final name = cleanRouteName.isEmpty ? module : extractName(cleanRouteName);

    return RouteModuleModel(
      params: shouldAppendParams ? params : null,
      name: name,
      child: child,
      route: route,
      module: normalizePath('/$module/'),
    );
  }

  static bool listEquals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String extractName(String path) {
    path = path.startsWith('/') ? path : '/$path';
    final regex = RegExp(r'^/([^/]+)/?');
    final match = regex.firstMatch(path);
    return match != null && match.groupCount >= 1 ? match.group(1)! : path;
  }

  static String resolvePath(String path) {
    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
