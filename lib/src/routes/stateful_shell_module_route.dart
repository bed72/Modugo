import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';

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
            return StatefulShellBranch(
              routes: route.module.configureRoutes(
                topLevel: false,
                path:
                    '${path.replaceAll(RegExp(r'/\$'), '')}/${route.path.replaceAll(RegExp(r'^/'), '')}',
              ),
            );
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
}
