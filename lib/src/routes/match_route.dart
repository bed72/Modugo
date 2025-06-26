import 'package:flutter/foundation.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// Represents the result of a route pattern match within Modugo.
///
/// Contains the matched route and the extracted path parameters from
/// the original input string.
///
/// This class is typically returned by [Modugo.matchRoute] or similar APIs.
///
/// Example:
/// ```dart
/// final result = Modugo.matchRoute('/product/42');
/// if (result != null) {
///   print(result.route); // ModuleRoute or ChildRoute
///   print(result.params); // { 'id': '42' }
/// }
/// ```
@immutable
final class MatchRoute {
  /// The matched route that owns the route pattern.
  final IModule route;

  /// The extracted parameters from the matched path.
  final Map<String, String> params;

  /// Creates a new [MatchRoute] with the given route and parameters.
  const MatchRoute({required this.route, required this.params});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchRoute &&
          runtimeType == other.runtimeType &&
          route == other.route &&
          mapEquals(params, other.params);

  @override
  int get hashCode => Object.hash(route, Object.hashAll(params.entries));

  @override
  String toString() => 'MatchRoute(route: $route, params: $params)';
}
