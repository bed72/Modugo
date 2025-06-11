import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';

import 'package:modugo/modugo.dart';
import 'package:modugo/src/logger.dart';

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
    required String path,
    required bool topLevel,
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
                  name: route.name,
                  builder: route.child,
                  redirect: route.redirect,
                  path: normalizePath(route.path),
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

  String normalizePath(String path) =>
      path.trim().isEmpty ? '/' : path.replaceAll(RegExp(r'/+'), '/');

  String composePath(String base, String sub) {
    final b = base.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final s = sub.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    if (b.isEmpty && s.isEmpty) return '/';

    final composed = [b, s].where((p) => p.isNotEmpty).join('/');

    return '/${composed.replaceAll(RegExp(r'/+'), '/')}';
  }
}
