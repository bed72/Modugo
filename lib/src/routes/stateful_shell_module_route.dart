import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// A modular route that enables stateful navigation using [StatefulShellRoute].
///
/// This is useful for apps that use tab-based or bottom navigation,
/// where each branch preserves its own navigation stack.
///
/// It composes multiple [IModule]s or [ChildRoute]s as independent branches,
/// and renders them via an [IndexedStack]-based layout using the provided [builder].
///
/// Each branch maintains its own stateful navigation context.
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
  const StatefulShellModuleRoute({required this.routes, required this.builder});

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
            final configuredRoutes = route.module.configureRoutes(
              path: '',
              topLevel: false,
            );

            final registeredPaths =
                configuredRoutes
                    .whereType<GoRoute>()
                    .map((r) => r.path)
                    .toList();

            Logger.info(
              '[BRANCH] "${route.path}" → registered GoRoutes: $registeredPaths',
            );

            return StatefulShellBranch(routes: configuredRoutes);
          }

          if (route is ChildRoute) {
            return StatefulShellBranch(
              routes: [
                GoRoute(
                  builder: route.child,
                  redirect: route.redirect,
                  path: normalizePath(route.path),
                  name: route.name ?? 'branch_$index',
                  parentNavigatorKey: route.parentNavigatorKey,
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
            'Invalid route type in StatefulShellModuleRoute: ${route.runtimeType}',
          );
        }).toList();

    return StatefulShellRoute.indexedStack(
      builder: builder,
      branches: branches,
    );
  }

  /// Normalizes a route [path] by trimming and collapsing repeated slashes.
  ///
  /// Returns `'/'` if the input is empty.
  String normalizePath(String path) =>
      path.trim().isEmpty ? '/' : path.replaceAll(RegExp(r'/+'), '/');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatefulShellModuleRoute &&
          builder == other.builder &&
          runtimeType == other.runtimeType &&
          listEquals(routes, other.routes);

  @override
  int get hashCode => Object.hashAll(routes) ^ builder.hashCode;
}
