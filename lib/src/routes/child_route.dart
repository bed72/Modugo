import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// A route that represents a direct child page within a [Module].
///
/// This is the most common route type in Modugo, used to register standard pages
/// in a module's `routes` list.
///
/// A `ChildRoute` maps a [path] to a widget via the [child] builder function,
/// and supports additional configuration like:
/// - named navigation via [name]
/// - transition customization via [transition]
/// - custom page composition via [pageBuilder]
/// - exit guards via [onExit]
/// - dynamic redirection via [redirect]
///
/// Example:
/// ```dart
/// ChildRoute(
///   '/product/:id',
///   name: 'product',
///   child: (context, state) => ProductPage(id: context.getPathParam('id')),
/// )
/// ```
@immutable
final class ChildRoute implements IModule {
  /// The relative path of this route, e.g. `'/'` or `'/product/:id'`.
  final String path;

  /// Optional name to support named navigation.
  final String? name;

  /// Optional transition animation for this route.
  ///
  /// Defaults to whatever is configured globally or by the router.
  final TypeTransition? transition;

  /// Navigator key to scope this route to a specific navigation stack (e.g. nested navigation).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// The builder function that returns the widget for this route.
  ///
  /// This is required unless [pageBuilder] is used.
  final Widget Function(BuildContext context, GoRouterState state) child;

  /// Optional function called before the route is popped.
  ///
  /// Return `false` to prevent leaving the page (like a route guard).
  final FutureOr<bool> Function(BuildContext context, GoRouterState state)?
  onExit;

  /// Optional function that builds a custom [Page] object.
  ///
  /// If provided, it overrides the default widget-based navigation.
  final Page<dynamic> Function(BuildContext context, GoRouterState state)?
  pageBuilder;

  /// Optional function that returns a new route path for redirection.
  ///
  /// Return `null` to allow the route to continue.
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  /// Creates a [ChildRoute] with the required [path] and [child] builder.
  ///
  /// Additional behavior like transition, guard, or redirection can be configured via optional parameters.
  const ChildRoute(
    this.path, {
    required this.child,
    this.name,
    this.onExit,
    this.redirect,
    this.transition,
    this.pageBuilder,
    this.parentNavigatorKey,
  });

  /// Returns a special [ChildRoute] that serves as a no-op root placeholder.
  ///
  /// Useful when a placeholder route is needed for structural reasons,
  /// such as avoiding GoRouter errors with empty shell branches.
  factory ChildRoute.safeRootRoute() => ChildRoute(
    '/',
    name: 'safe-root-route',
    child: (_, __) => const SizedBox.shrink(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildRoute &&
          path == other.path &&
          name == other.name &&
          transition == other.transition &&
          runtimeType == other.runtimeType &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      transition.hashCode ^
      parentNavigatorKey.hashCode;
}
