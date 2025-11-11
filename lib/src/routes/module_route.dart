import 'package:flutter/widgets.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

/// A route that maps a [path] to a child [Module] within the Modugo navigation system.
///
/// This allows composing modular navigation trees by associating a sub-[Module]
/// with a specific path segment. The nested module can define its own routes,
/// bindings, and structure independently.
///
/// You can also optionally:
/// - assign a [name] for named navigation
/// - optional [parentNavigatorKey]
///
/// Example:
/// ```dart
/// ModuleRoute(
///   path: '/product',
///   name: 'product-root',
///   module: ProductModule(),
///   redirect: (context, state) {
///     final isLogged = context.read<AuthService>().isLoggedIn;
///     return isLogged ? null : '/login';
///   },
/// );
/// ```
@immutable
final class ModuleRoute implements IRoute {
  final String path;

  /// Optional name for named navigation or route identification.
  final String? name;

  /// The child [Module] associated with this route.
  ///
  /// This module will provide its own routes and bindings.
  final Module module;

  /// The navigator key of the parent (for nested navigator hierarchy).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Creates a [ModuleRoute] that links a [path] to a nested [module].
  const ModuleRoute({
    required this.path,
    required this.module,
    this.name,
    this.parentNavigatorKey,
  });

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      module.hashCode ^
      parentNavigatorKey.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleRoute &&
          path == other.path &&
          name == other.name &&
          module == other.module &&
          runtimeType == other.runtimeType &&
          parentNavigatorKey == other.parentNavigatorKey;
}
