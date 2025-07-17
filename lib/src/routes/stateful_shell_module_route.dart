// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';

/// A modular route that enables stateful navigation using [StatefulShellRoute].
///
/// This is useful for apps that use tab-based or bottom navigation,
/// where each branch preserves its own navigation stack.
///
/// It composes multiple [IModule]s or [ChildRoute]s as independent branches,
/// and renders them via an [IndexedStack]-based layout using the provided [builder].
///
/// Each branch maintains its own stateful navigation context.
/// The shell provides:
/// - a shared [key] for nested navigation
/// - optional [restorationScopeId], and [parentNavigatorKey]
///
/// Optionally supports [routePattern] to enable custom regex-based
/// matching and parameter extraction independent of GoRouter.
///
/// Example:
/// ```dart
/// StatefulShellModuleRoute(
///   routes: [
///     ModuleRoute('/home', module: HomeModule()),
///     ModuleRoute('/profile', module: ProfileModule()),
///   ],
///   builder: (context, state, shell) {
///     return AppScaffold(navigationShell: shell);
///   },
/// );
/// ```
@immutable
final class StatefulShellModuleRoute implements IModule {
  /// The list of modules or routes that form each branch of the shell.
  ///
  /// Each item represents a separate navigation stack.
  final List<IModule> routes;

  /// Optional ID used for state restoration (Flutter feature).
  final String? restorationScopeId;

  /// Optional route matching pattern using regex and parameter names.
  ///
  /// This allows the module to be matched via a regular expression
  /// independently of GoRouter's matching logic.
  final RoutePatternModel? routePattern;

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
    this.routePattern,
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  /// Converts this module into a [RouteBase] for GoRouter.
  ///
  /// This method configures each branch individually. It supports:
  /// - [ModuleRoute]: will call `configureRoutes` internally
  /// - [ChildRoute]: will wrap into a [GoRoute] inside a single-branch shell
  ///
  /// Throws:
  /// - [UnsupportedError] if a route is not a [ModuleRoute] or [ChildRoute].
  RouteBase toRoute({required String path, required bool topLevel}) {
    final branches =
        routes.asMap().entries.map((entry) {
          final index = entry.key;
          final route = entry.value;

          if (route is ModuleRoute) {
            return StatefulShellBranch(
              navigatorKey: route.parentNavigatorKey,
              routes: route.module.configureRoutes(topLevel: false),
            );
          }

          if (route is ChildRoute) {
            return StatefulShellBranch(
              routes: [
                GoRoute(
                  builder: route.child,
                  redirect: route.redirect,
                  name: route.name ?? 'branch_$index',
                  path: route.path.isEmpty ? '/' : route.path,
                  pageBuilder:
                      route.pageBuilder != null
                          ? (context, state) =>
                              route.pageBuilder!(context, state)
                          : null,
                ),
              ],
            );
          }

          throw UnsupportedError(
            'Unsupported route type in StatefulShellModuleRoute: ${route.runtimeType}',
          );
        }).toList();

    return StatefulShellRoute.indexedStack(
      key: key,
      builder: builder,
      branches: branches,
      parentNavigatorKey: parentNavigatorKey,
      restorationScopeId: restorationScopeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatefulShellModuleRoute &&
          builder == other.builder &&
          listEquals(routes, other.routes) &&
          runtimeType == other.runtimeType &&
          routePattern == other.routePattern &&
          key == other.key &&
          restorationScopeId == other.restorationScopeId &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      builder.hashCode ^
      routePattern.hashCode ^
      key.hashCode ^
      restorationScopeId.hashCode ^
      parentNavigatorKey.hashCode;
}
