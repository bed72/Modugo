import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

/// A route that represents a pure redirection within a [Module].
///
/// Unlike [ChildRoute], this route does not build a widget or page.
/// It exists only to map one path to another.
///
/// Example:
/// ```dart
/// RedirectRoute(
///   path: '/old/:id',
///   redirect: (context, state) {
///     final id = state.pathParameters['id'];
///     return '/new/$id';
///   },
/// )
/// ```
@immutable
final class RedirectRoute implements IRoute {
  /// The relative path of this route, e.g. `'/old/:id'`.
  final String path;

  /// Optional name to support named navigation.
  final String? name;

  /// Optional list of guards executed before applying redirect.
  ///
  /// Each guard can allow the navigation or return a redirect path.
  final List<IGuard> guards;

  /// Function that computes the new route path for redirection.
  ///
  /// Return `null` to allow the route to continue.
  final FutureOr<String?> Function(BuildContext, GoRouterState) redirect;

  /// Creates a [RedirectRoute] with the required [path] and [redirect] callback.
  const RedirectRoute({
    required this.path,
    required this.redirect,
    this.name,
    this.guards = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedirectRoute &&
          path == other.path &&
          name == other.name &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => path.hashCode ^ name.hashCode;
}
