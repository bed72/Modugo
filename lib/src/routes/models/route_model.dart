import 'package:flutter/material.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/paths/path.dart';

/// A model that represents a route definition tied to a specific module in Modugo.
///
/// This class encapsulates all the necessary information to generate, match,
/// and navigate to routes associated with a [Module], including:
/// - full path
/// - local child path
/// - module base path
/// - optional dynamic parameters
/// - named route reference
/// - route transition
///
/// It also provides utilities to construct full paths dynamically, handling:
/// - parameter injection
/// - subpath composition
/// - route name extraction
@immutable
final class RouteModuleModel {
  /// The unique name used for this route (if any).
  final String name;

  /// The normalized full route path (e.g. `/shop/products`).
  final String route;

  /// The internal path segment relative to the [module] (e.g. `/products/:id`).
  final String child;

  /// The normalized module path prefix (e.g. `/shop/`).
  final String module;

  /// Optional list of dynamic parameter names (e.g. `['id']`).
  final List<String>? params;

  /// The type of transition animation applied during navigation.
  final TypeTransition transition;

  /// Creates a [RouteModuleModel] with all required properties.
  ///
  /// Most routes should be built using the [RouteModuleModel.build] factory.
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

  /// Constructs the full route path, injecting [params] and [subParams] into the pattern.
  ///
  /// This is used at runtime to build a valid navigable route from this model.
  ///
  /// Example:
  /// ```dart
  /// final model = RouteModuleModel(...);
  /// final path = model.buildPath(params: ['42'], subParams: ['details']);
  /// ```
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

  /// Factory method to create a [RouteModuleModel] based on a module path and route pattern.
  ///
  /// This method:
  /// - sanitizes and normalizes the route name
  /// - appends dynamic parameters if necessary
  /// - builds the route, child, and module fields accordingly
  ///
  /// Example:
  /// ```dart
  /// RouteModuleModel.build(
  ///   module: 'shop',
  ///   routeName: 'product',
  ///   params: ['id'],
  /// );
  /// ```
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

  /// Compares two lists of strings for deep equality.
  ///
  /// Returns `true` if both lists are null or contain equal items.
  static bool listEquals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Extracts the base name of the route from a given path.
  ///
  /// Example:
  /// ```dart
  /// extractName('/product/details'); // → 'product'
  /// ```
  static String extractName(String path) {
    path = path.startsWith('/') ? path : '/$path';
    final regex = RegExp(r'^/([^/]+)/?');
    final match = regex.firstMatch(path);
    return match != null && match.groupCount >= 1 ? match.group(1)! : path;
  }

  /// Normalizes and resolves a route path by removing redundant slashes and trailing slashes.
  ///
  /// Ensures a consistent format for route comparison and registration.
  static String resolvePath(String path) {
    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
