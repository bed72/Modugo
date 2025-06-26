import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// A route that maps a [path] to a child [Module] within the Modugo navigation system.
///
/// This allows composing modular navigation trees by associating a sub-[Module]
/// with a specific path segment. The nested module can define its own routes,
/// bindings, and structure independently.
///
/// You can also optionally:
/// - assign a [name] for named navigation
/// - add a [redirect] function to control access dynamically
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
  final String path;

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

  /// Optional function that redirects the user to another path
  /// before entering the module.
  ///
  /// Returning `null` allows access. Returning a string will redirect to that path.
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  /// Creates a [ModuleRoute] that links a [path] to a nested [module].
  const ModuleRoute(
    this.path, {
    required this.module,
    this.name,
    this.redirect,
    this.guards = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleRoute &&
          path == other.path &&
          name == other.name &&
          module == other.module &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => path.hashCode ^ name.hashCode ^ module.hashCode;
}
