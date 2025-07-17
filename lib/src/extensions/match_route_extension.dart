// coverage:ignore-file

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/match_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Extension on [MatchRoute] to extract detailed route information
/// from the underlying [IModule] using pattern matching.
///
/// These helpers provide convenient access to the matched route's
/// `name`, `path`, and `type`, without requiring manual type checks.
extension MatchRouteExtension on MatchRoute {
  /// Returns the matched route as a [ChildRoute] if applicable.
  ChildRoute? get asChildRoute =>
      route is ChildRoute ? route as ChildRoute : null;

  /// Returns the matched route as a [ModuleRoute] if applicable.
  ModuleRoute? get asModuleRoute =>
      route is ModuleRoute ? route as ModuleRoute : null;

  /// Returns the matched route as a [ShellModuleRoute] if applicable.
  ShellModuleRoute? get asShellModuleRoute =>
      route is ShellModuleRoute ? route as ShellModuleRoute : null;

  /// Returns the matched route as a [StatefulShellModuleRoute] if applicable.
  StatefulShellModuleRoute? get asStatefulShellModuleRoute =>
      route is StatefulShellModuleRoute
          ? route as StatefulShellModuleRoute
          : null;

  /// Returns the `name` of the matched route, if available.
  ///
  /// This inspects the concrete type of [route] and extracts its `name`
  /// property when applicable. Returns `null` for unknown types.
  ///
  /// Example:
  /// ```dart
  /// final match = Modugo.matchRoute('/profile');
  /// print(match?.name); // e.g. 'profile-route'
  /// ```
  String? get name => switch (route) {
    ChildRoute(:final name) => name,
    ModuleRoute(:final name) => name,
    _ => null,
  };

  /// Returns the `path` of the matched route, if available.
  ///
  /// This is useful for logging or debugging matched route patterns.
  /// Returns `null` if the route type does not expose a `path`.
  ///
  /// Example:
  /// ```dart
  /// final match = Modugo.matchRoute('/cart.do');
  /// print(match?.path); // e.g. '/cart.do'
  /// ```
  String? get path => switch (route) {
    ChildRoute(:final path) => path,
    ModuleRoute(:final path) => path,
    _ => null,
  };

  /// Returns the name of the concrete type of the matched route.
  ///
  /// This is helpful for diagnostics, debugging, or analytics when
  /// you want to categorize the type of route being used.
  ///
  /// Example:
  /// ```dart
  /// final match = Modugo.matchRoute('/checkout');
  /// print(match?.typeName); // e.g. 'ModuleRoute'
  /// ```
  String get typeName => switch (route) {
    ChildRoute() => 'ChildRoute',
    ModuleRoute() => 'ModuleRoute',
    ShellModuleRoute() => 'ShellModuleRoute',
    StatefulShellModuleRoute() => 'StatefulShellModuleRoute',
    _ => 'Unknown',
  };
}
