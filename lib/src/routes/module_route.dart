import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/models/route_pattern_model.dart';

/// A route that maps a [path] to a child [Module] within the Modugo navigation system.
///
/// This allows composing modular navigation trees by associating a sub-[Module]
/// with a specific path segment. The nested module can define its own routes,
/// bindings, and structure independently.
///
/// You can also optionally:
/// - assign a [name] for named navigation
/// - optional [parentNavigatorKey]
/// - add a [redirect] function to control access dynamically
///
/// Optionally supports [routePattern] to enable custom regex-based
/// matching and parameter extraction independent of GoRouter.
///
/// Example:
/// ```dart
/// ModuleRoute(
///   '/product',
///   name: 'product-root',
///   module: ProductModule(),
///   redirect: (context, state) {
///     final isLogged = context.read<AuthService>().isLoggedIn;
///     return isLogged ? null : '/login';
///   },
/// );
/// ```
@immutable
final class ModuleRoute implements IModule {
  /// The path at which this module is mounted (e.g. `/shop`, `/admin/users`).
  /// If not passed or null the default value is '/'
  final String? path;

  /// Optional name for named navigation or route identification.
  final String? name;

  /// The child [Module] associated with this route.
  ///
  /// This module will provide its own routes and bindings.
  final Module module;

  /// Optional list of guards that control access to this module.
  ///
  /// Each guard can redirect to another path or allow access.
  final List<IGuard> guards;

  /// Optional route matching pattern using regex and parameter names.
  ///
  /// This allows the module to be matched via a regular expression
  /// independently of GoRouter's matching logic.
  final RoutePatternModel? routePattern;

  /// The navigator key of the parent (for nested navigator hierarchy).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Optional function that redirects the user to another path
  /// before entering the module.
  ///
  /// Returning `null` allows access. Returning a string will redirect to that path.
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  /// Creates a [ModuleRoute] that links a [path] to a nested [module].
  const ModuleRoute({
    required this.module,
    this.name,
    this.redirect,
    this.path = '/',
    this.routePattern,
    this.guards = const [],
    this.parentNavigatorKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleRoute &&
          path == other.path &&
          name == other.name &&
          module == other.module &&
          runtimeType == other.runtimeType &&
          routePattern == other.routePattern &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      module.hashCode ^
      routePattern.hashCode ^
      parentNavigatorKey.hashCode;
}
