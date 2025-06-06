import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';
import 'package:modugo/modugo.dart';
import 'package:modugo/src/logger.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class StatefulShellModuleRoute extends Equatable
    implements ModuleInterface {
  final List<ModuleInterface> routes;
  final Widget Function(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  )
  builder;

  const StatefulShellModuleRoute({required this.routes, required this.builder});

  RouteBase toRoute({
    required bool topLevel,
    required String path,
  }) => StatefulShellRoute.indexedStack(
    builder: builder,
    branches:
        routes.map((route) {
          if (route is ModuleRoute) {
            final composedPath = composePath(path, route.path);
            final configuredRoutes = route.module.configureRoutes(
              topLevel: false,
              path: composedPath,
            );

            if (Modugo.debugLogDiagnostics) {
              final goPaths =
                  configuredRoutes
                      .whereType<GoRoute>()
                      .map((r) => r.path)
                      .toList();
              ModugoLogger.info(
                '🧭 Branch "${route.path}" → composedPath="$composedPath" → registered GoRoutes: $goPaths',
              );
            }

            return StatefulShellBranch(routes: configuredRoutes);
          }

          if (route is ChildRoute) {
            return StatefulShellBranch(
              routes: [
                GoRoute(
                  path: route.path,
                  name: route.name,
                  builder: route.child,
                  redirect: route.redirect,
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
            'Invalid route type in Stateful Shell Module Route',
          );
        }).toList(),
  );

  @override
  List<Object?> get props => [routes, builder];

  String composePath(String base, String sub) {
    if (base == '/') base = '';
    if (sub == '/') sub = '';
    return [
      base,
      sub,
    ].where((s) => s.isNotEmpty).join('/').replaceAll(RegExp(r'/+'), '/');
  }
}
