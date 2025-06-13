import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class StatefulShellModuleRoute implements ModuleInterface {
  final List<ModuleInterface> routes;
  final List<String?>? initialPathsPerBranch;
  final Widget Function(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  )
  builder;

  const StatefulShellModuleRoute({
    required this.routes,
    required this.builder,
    this.initialPathsPerBranch,
  }) : assert(
         initialPathsPerBranch == null ||
             initialPathsPerBranch.length == routes.length,
         'initialPathsPerBranch must match the length of routes',
       );

  RouteBase toRoute({required String path, required bool topLevel}) {
    return StatefulShellRoute.indexedStack(
      builder: builder,
      branches:
          routes.asMap().entries.map((entry) {
            final index = entry.key;
            final route = entry.value;
            final initialPath = initialPathsPerBranch?[index];

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

              return StatefulShellBranch(
                routes: configuredRoutes,
                initialLocation: initialPath,
              );
            }

            if (route is ChildRoute) {
              final composedPath = composePath(path, route.path);
              return StatefulShellBranch(
                initialLocation: initialPath,
                routes: [
                  GoRoute(
                    path: normalizePath(composedPath),
                    name: route.name ?? 'branch_$index',
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
              'Invalid route type in StatefulShellModuleRoute: ${route.runtimeType}',
            );
          }).toList(),
    );
  }

  String normalizePath(String path) =>
      path.trim().isEmpty ? '/' : path.replaceAll(RegExp(r'/+'), '/');

  String composePath(String base, String sub) {
    final cleanSub = sub.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final cleanBase = base.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    if (cleanBase.isEmpty && cleanSub.isEmpty) return '/';

    final composed = [cleanBase, cleanSub].where((p) => p.isNotEmpty).join('/');
    return '/${composed.replaceAll(RegExp(r'/+'), '/')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatefulShellModuleRoute &&
          builder == other.builder &&
          runtimeType == other.runtimeType &&
          listEquals(routes, other.routes) &&
          listEquals(initialPathsPerBranch, other.initialPathsPerBranch);

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      Object.hashAll(initialPathsPerBranch ?? []) ^
      builder.hashCode;
}
