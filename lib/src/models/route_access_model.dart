import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

/// A model representing an accessed route within the Modugo routing system.
///
/// This is used internally to track active routes associated with a given [Module],
/// allowing proper cleanup and dependency management based on navigation behavior.
///
/// It stores both:
/// - the absolute [path] of the accessed route
/// - an optional [branch], used primarily in `StatefulShellModuleRoute` contexts
///
/// Example:
/// ```dart
/// final route = RouteAccessModel('/profile', 'user-tab');
/// debugPrint(route.toString()); // → RouteAccessModel(/profile, user-tab)
/// ```
@immutable
final class RouteAccessModel {
  /// The absolute path of the accessed route.
  final String path;

  /// The navigation branch this route belongs to, if applicable.
  ///
  /// Used to differentiate between different shell branches (e.g. tabs).
  final String? branch;

  /// Creates a [RouteAccessModel] with a [path] and an optional [branch].
  const RouteAccessModel(this.path, [this.branch]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteAccessModel &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          branch == other.branch;

  @override
  int get hashCode => Object.hash(path, branch);

  @override
  String toString() => 'RouteAccessModel($path, $branch)';
}
