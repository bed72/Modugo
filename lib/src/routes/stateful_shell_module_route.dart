import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class StatefulShellModuleRoute implements IModule {
  final List<IModule> routes;
  final Widget Function(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  )
  builder;

  const StatefulShellModuleRoute({required this.routes, required this.builder});

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

            if (Modugo.debugLogDiagnostics) {
              final registeredPaths =
                  configuredRoutes
                      .whereType<GoRoute>()
                      .map((r) => r.path)
                      .toList();

              Logger.info(
                '[BRANCH] "${route.path}" → registered GoRoutes: $registeredPaths',
              );
            }

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
