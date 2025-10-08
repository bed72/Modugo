import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Factory responsible for converting [IRoute] lists into [RouteBase]s for GoRouter.
///
/// It centralizes all route creation logic for:
/// - [ChildRoute]
/// - [ModuleRoute]
/// - [AliasRoute]
/// - [ShellModuleRoute]
/// - [StatefulShellModuleRoute]
///
/// Supports contextual resolution: aliases, nested modules, and shells.
final class RoutesFactory {
  const RoutesFactory._();

  static List<RouteBase> from(List<IRoute> routes) {
    final childs = <GoRoute>[];
    final modules = <GoRoute>[];
    final shells = <RouteBase>[];

    for (final route in routes) {
      switch (route) {
        case ChildRoute():
          childs.add(_createChild(route));

        case AliasRoute():
          childs.add(_createAlias(route, routes));

        case ModuleRoute():
          modules.add(_createModule(route));

        case ShellModuleRoute():
          shells.add(_createShell(route));

        case StatefulShellModuleRoute():
          shells.add(_createStatefulShell(route));

        case _:
          throw UnsupportedError(
            'Unsupported route type: ${route.runtimeType}',
          );
      }
    }

    return [...shells, ...childs, ...modules];
  }

  static GoRoute _createChild(ChildRoute route) {
    _validatePath(route.path!, 'ChildRoute');

    return GoRoute(
      name: route.name,
      path: route.path!,
      parentNavigatorKey: route.parentNavigatorKey,
      redirect:
          (context, state) async => _safeAsync(
            label: 'ChildRouteRedirect',
            state: state,
            build: () async {
              for (final guard in route.guards) {
                final safety = await guard(context, state);
                if (safety != null) return safety;
              }

              return null;
            },
          ),
      builder:
          (context, state) => _safe(
            state: state,
            label: 'ChildRouteBuilder',
            build: () => route.child(context, state),
          ),
      pageBuilder:
          route.pageBuilder == null
              ? (context, state) => _transition(context, state, route)
              : (context, state) => _safe(
                state: state,
                label: 'ChildRoutePageBuilder',
                build: () => route.pageBuilder!(context, state),
              ),
    );
  }

  static GoRoute _createAlias(AliasRoute alias, List<IRoute> routes) {
    final target = routes.whereType<ChildRoute>().firstWhere(
      (child) => child.path == alias.to,
      orElse:
          () =>
              throw ArgumentError(
                'Alias "${alias.from}" points to "${alias.to}", but no matching ChildRoute was found.',
              ),
    );

    _validatePath(alias.from, 'AliasRoute');

    return GoRoute(
      path: alias.from,
      redirect:
          (context, state) async => _safeAsync(
            state: state,
            label: 'AliasRouteRedirect',
            build: () async {
              for (final guard in target.guards) {
                final safety = await guard(context, state);
                if (safety != null) return safety;
              }

              return null;
            },
          ),

      builder:
          (context, state) => _safe(
            state: state,
            label: 'AliasRouteBuilder',
            build: () => target.child(context, state),
          ),
      pageBuilder:
          target.pageBuilder == null
              ? (context, state) => _transition(context, state, target)
              : (context, state) => _safe(
                state: state,
                label: 'AliasRoutePageBuilder',
                build: () => target.pageBuilder!(context, state),
              ),
    );
  }

  static GoRoute _createModule(ModuleRoute route) {
    final module = route.module;
    final first = module.routes().whereType<ChildRoute>().firstOrNull;

    if (first == null) {
      throw StateError(
        'ModuleRoute "${route.name ?? module.runtimeType}" '
        'does not define any ChildRoute. Each Module must have at least one ChildRoute '
        'to determine its initial builder.',
      );
    }

    _validatePath(first.path!, 'ModuleRoute');

    return GoRoute(
      name: route.name,
      path: route.path!,
      routes: module.configureRoutes(),
      parentNavigatorKey: route.parentNavigatorKey ?? first.parentNavigatorKey,
      redirect:
          (context, state) async => _safeAsync(
            state: state,
            label: 'ModuleRouteRedirect',
            build: () async {
              if (module is GuardModuleDecorator) {
                for (final guard in module.guards) {
                  final safety = await guard(context, state);
                  if (safety != null) return safety;
                }
              }

              return null;
            },
          ),
      builder:
          (context, state) => _safe(
            state: state,
            label: 'ModuleRoute',
            build: () => first.child(context, state),
          ),
    );
  }

  static ShellRoute _createShell(ShellModuleRoute route) {
    final routes =
        route.routes
            .map(
              (child) =>
                  child is ModuleRoute
                      ? _createModule(child)
                      : child is ChildRoute
                      ? _createChild(child)
                      : null,
            )
            .whereType<RouteBase>()
            .toList();

    return ShellRoute(
      routes: routes,
      observers: route.observers,
      navigatorKey: route.navigatorKey,
      parentNavigatorKey: route.parentNavigatorKey,
      builder:
          (context, state, child) => _safe(
            state: state,
            label: 'ShellRouteBuilder',
            build: () => route.builder!(context, state, child),
          ),
      pageBuilder:
          route.pageBuilder == null
              ? null
              : (context, state, child) => _safe(
                state: state,
                label: 'ShellRoutePageBuilder',
                build: () => route.pageBuilder!(context, state, child),
              ),
    );
  }

  static StatefulShellRoute _createStatefulShell(
    StatefulShellModuleRoute route,
  ) {
    final branches =
        route.routes.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          if (child is ModuleRoute) {
            return StatefulShellBranch(
              routes: child.module.configureRoutes(),
              navigatorKey: child.parentNavigatorKey,
            );
          }

          if (child is ChildRoute) {
            return StatefulShellBranch(
              routes: [
                _createChild(
                  ChildRoute(
                    child: child.child,
                    guards: child.guards,
                    transition: child.transition,
                    pageBuilder: child.pageBuilder,
                    name: child.name ?? 'branch_$index',
                    parentNavigatorKey: child.parentNavigatorKey,
                    path: child.path!.isEmpty ? '/' : child.path!,
                  ),
                ),
              ],
            );
          }

          throw UnsupportedError(
            'Unsupported route type inside StatefulShellModuleRoute: ${child.runtimeType}',
          );
        }).toList();

    return StatefulShellRoute.indexedStack(
      key: route.key,
      branches: branches,
      parentNavigatorKey: route.parentNavigatorKey,
      builder:
          (context, state, shell) => _safe(
            state: state,
            label: 'StatefulShellRouteBuilder',
            build: () => route.builder(context, state, shell),
          ),
    );
  }

  static T _safe<T>({
    required String label,
    required T Function() build,
    required GoRouterState state,
  }) {
    try {
      return build();
    } catch (exception, stack) {
      Logger.error(
        'Error building $label for ${state.uri}: $exception\n$stack',
      );

      rethrow;
    }
  }

  static FutureOr<T> _safeAsync<T>({
    required String label,
    required GoRouterState state,
    required FutureOr<T> Function() build,
  }) async {
    try {
      return await build();
    } catch (exception, stack) {
      Logger.error(
        'Error building $label for ${state.uri}: $exception\n$stack',
      );

      rethrow;
    }
  }

  static Page<void> _transition(
    BuildContext context,
    GoRouterState state,
    ChildRoute route,
  ) => CustomTransitionPage(
    key: state.pageKey,
    child: route.child(context, state),
    transitionsBuilder: Transition.builder(
      config: () {},
      type: route.transition ?? Modugo.getDefaultTransition,
    ),
  );

  static void _validatePath(String path, String type) {
    try {
      final compiler = CompilerRoute(path);
      Logger.navigation('[$type] Valid path: ${compiler.pattern}');
    } catch (exception) {
      Logger.error('Invalid path in $type: $path → $exception');
      throw ArgumentError.value(
        path,
        'path',
        'Invalid syntax in $type: $exception',
      );
    }
  }
}
