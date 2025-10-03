import 'package:flutter/widgets.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

/// A route that represents an **alias** for another [ChildRoute].
///
/// Unlike [ChildRoute], this route does not define its own [child] or [pageBuilder].
/// Instead, it delegates rendering to the [destination] route within the same module.
///
/// This is useful when you want multiple paths to resolve to the same page,
/// such as supporting legacy URLs, SEO-friendly routes, or alternate entry points.
///
/// Example:
/// ```dart
/// AliasRoute(
///   alias: '/cart/:id',
///   detination: '/order/:id',
/// )
/// ```
@immutable
final class AliasRoute implements IRoute {
  /// The alias path for this route, e.g. `'/cart/:id'`.
  final String alias;

  /// The canonical path of the [ChildRoute] this alias should resolve to.
  final String destination;

  /// Creates an [AliasRoute] pointing to an existing [ChildRoute] identified by [destination].
  const AliasRoute({required this.alias, required this.destination});

  @override
  int get hashCode => alias.hashCode ^ destination.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AliasRoute &&
          alias == other.alias &&
          destination == other.destination &&
          runtimeType == other.runtimeType;
}
