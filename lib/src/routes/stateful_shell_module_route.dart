// ignore_for_file: use_build_context_synchronously

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/child_route.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

/// A modular route that enables stateful navigation using [StatefulShellRoute].
///
/// This is useful for apps that use tab-based or bottom navigation,
/// where each branch preserves its own navigation stack.
///
/// It composes multiple [IRoute]s or [ChildRoute]s as independent branches,
/// and renders them via an [IndexedStack]-based layout using the provided [builder].
///
/// Each branch maintains its own stateful navigation context.
/// The shell provides:
/// - a shared [key] for nested navigation
/// - optional [parentNavigatorKey]
///
/// Example:
/// ```dart
/// StatefulShellModuleRoute(
///   routes: [
///     ModuleRoute(path: '/home', module: HomeModule()),
///     ModuleRoute(path: '/profile', module: ProfileModule()),
///   ],
///   builder: (context, state, shell) {
///     return AppScaffold(navigationShell: shell);
///   },
/// );
/// ```
@immutable
final class StatefulShellModuleRoute implements IRoute {
  /// The list of modules or routes that form each branch of the shell.
  ///
  /// Each item represents a separate navigation stack.
  final List<IRoute> routes;

  /// Navigator key used to isolate navigation inside the shell.
  final GlobalKey<StatefulNavigationShellState>? key;

  /// The navigator key of the parent (for nested navigator hierarchy).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// The widget builder for rendering the full shell layout with tabs.
  ///
  /// It provides access to the current [GoRouterState] and the [StatefulNavigationShell],
  /// which manages tab switching and navigation state.
  final Widget Function(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  )
  builder;

  /// Creates a [StatefulShellModuleRoute] with the provided branch [routes] and [builder].
  const StatefulShellModuleRoute({
    required this.routes,
    required this.builder,
    this.key,
    this.parentNavigatorKey,
  });

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      key.hashCode ^
      builder.hashCode ^
      parentNavigatorKey.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatefulShellModuleRoute &&
          key == other.key &&
          builder == other.builder &&
          listEquals(routes, other.routes) &&
          runtimeType == other.runtimeType &&
          parentNavigatorKey == other.parentNavigatorKey;
}
