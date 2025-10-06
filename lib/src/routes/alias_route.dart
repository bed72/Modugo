import 'package:flutter/widgets.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

/// A route that represents an **alias** for another [ChildRoute].
///
/// Unlike [ChildRoute], this route does not define its own [child] or [pageBuilder].
/// Instead, it delegates rendering to the [to] route within the same module.
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
  /// The canonical path of the [ChildRoute] this alias should resolve to.
  final String to;

  /// The alias path for this route, e.g. `'/cart/:id'`.
  final String from;

  /// Creates an [AliasRoute] pointing to an existing [ChildRoute] identified by [to].
  const AliasRoute({required this.from, required this.to});

  @override
  int get hashCode => to.hashCode ^ from.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AliasRoute &&
          to == other.to &&
          from == other.from &&
          runtimeType == other.runtimeType;
}
