// ignore_for_file: use_build_context_synchronously

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

            final updatedRoutes =
                configuredRoutes.map((r) {
                  if (r is! GoRoute) return r;

                  final isRoot =
                      r.path == route.path || r.path == '/' || r.path == '';

                  if (!isRoot) return r;

                  return GoRoute(
                    path: r.path,
                    name: r.name,
                    builder: r.builder,
                    pageBuilder: r.pageBuilder,
                    parentNavigatorKey: r.parentNavigatorKey,
                    onExit: r.onExit,
                    redirect: (context, state) async {
                      for (final guard in route.guards) {
                        final result = await guard.redirect(context, state);
                        if (result != null) return result;
                      }

                      if (route.redirect != null) {
                        final result = route.redirect!(context, state);
                        if (result != null) return result;
                      }

                      return await r.redirect?.call(context, state);
                    },
                  );
                }).toList();

            final registeredPaths =
                updatedRoutes.whereType<GoRoute>().map((r) => r.path).toList();
            ModugoLogger.navigation(
              '"${route.path}" → registered GoRoutes: $registeredPaths',
            );

            return StatefulShellBranch(routes: updatedRoutes);
          }

          if (route is ChildRoute) {
            return StatefulShellBranch(
              routes: [
                GoRoute(
                  builder: route.child,
                  path: normalizePath(route.path),
                  name: route.name ?? 'branch_$index',
                  parentNavigatorKey: route.parentNavigatorKey,
                  pageBuilder:
                      route.pageBuilder != null
                          ? (context, state) =>
                              route.pageBuilder!(context, state)
                          : null,
                  redirect: (context, state) async {
                    for (final guard in route.guards) {
                      final result = await guard.redirect(context, state);
                      if (result != null) return result;
                    }

                    if (route.redirect != null) {
                      final result = await route.redirect!(context, state);
                      if (result != null) return result;
                    }

                    return null;
                  },
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
