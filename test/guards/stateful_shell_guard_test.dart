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

/// Factory responsible for converting [IRoute]s into [RouteBase] objects.
///
/// It supports all Modugo route types and handles nested structures,
/// guards, alias resolution, and module recursion.
///
/// Example:
/// ```dart
/// final routes = RoutesFactory.fromAll(module.routes());
/// ```
///
/// Or for a single route:
/// ```dart
/// final route = RoutesFactory.from(route);
/// ```
final class RoutesFactory {
  const RoutesFactory._();

  /// Builds a list of [RouteBase] from a collection of [IRoute]s.
  static List<RouteBase> fromAll(List<IRoute> routes) {
    return routes.expand((r) => _from(r, routes)).toList();
  }

  /// Builds a single [RouteBase] from a single [IRoute].
  ///
  /// For consistency with tests and existing code, this method is still
  /// supported and returns the **first** route from [_from].
  static RouteBase from(IRoute route, {List<IRoute> context = const []}) {
    return _from(route, context).first;
  }

  /// Internal dispatcher that can return multiple routes (e.g. aliases).
  static List<RouteBase> _from(IRoute route, List<IRoute> context) {
    switch (route) {
      case ChildRoute():
        return [_child(route)];

      case AliasRoute():
        return [_alias(route, context)];

      case ModuleRoute():
        return [_module(route)];

      case ShellModuleRoute():
        return [_shell(route)];

      case StatefulShellModuleRoute():
        return [_statefulShell(route)];

      default:
        throw UnsupportedError('Unsupported route type: $route');
    }
  }

  // ====== Builders ======

  static GoRoute _child(ChildRoute route) {
    _validatePath(route.path!, 'ChildRoute');

    return GoRoute(
      path: route.path!,
      name: route.name,
      parentNavigatorKey: route.parentNavigatorKey,
      redirect: (context, state) async {
        for (final guard in route.guards) {
          final value = await guard(context, state);
          if (value != null) return value;
        }
        return null;
      },
      builder:
          (context, state) => _safe(
            state: state,
            label: 'ChildRoute',
            build: () => route.child(context, state),
          ),
      pageBuilder:
          route.pageBuilder == null
              ? (context, state) => _transition(context, state, route)
              : (context, state) => _safe(
                state: state,
                label: 'ChildRoute.pageBuilder',
                build: () => route.pageBuilder!(context, state),
              ),
    );
  }

  static GoRoute _alias(AliasRoute alias, List<IRoute> contextRoutes) {
    final target = contextRoutes.whereType<ChildRoute>().firstWhere(
      (r) => r.path == alias.to,
      orElse:
          () =>
              throw ArgumentError(
                'AliasRoute "${alias.from}" points to missing target "${alias.to}"',
              ),
    );

    _validatePath(alias.from, 'AliasRoute');

    return GoRoute(
      path: alias.from,
      redirect: (context, state) async {
        for (final guard in target.guards) {
          final value = await guard(context, state);
          if (value != null) return value;
        }
        return null;
      },
      builder:
          (context, state) => _safe(
            state: state,
            label: 'AliasRoute',
            build: () => target.child(context, state),
          ),
      pageBuilder:
          target.pageBuilder == null
              ? (context, state) => _transition(context, state, target)
              : (context, state) => _safe(
                state: state,
                label: 'AliasRoute.pageBuilder',
                build: () => target.pageBuilder!(context, state),
              ),
    );
  }

  static GoRoute _module(ModuleRoute route) {
    final child = route.module.routes().whereType<ChildRoute>().firstOrNull;

    if (child == null) {
      return GoRoute(
        path: route.path!,
        builder: (_, __) => const SizedBox.shrink(),
      );
    }

    _validatePath(child.path!, 'ModuleRoute');

    return GoRoute(
      path: route.path!,
      name: route.name,
      routes: route.module.configureRoutes(),
      parentNavigatorKey: route.parentNavigatorKey ?? child.parentNavigatorKey,
      redirect: (context, state) async {
        if (route.module is GuardModuleDecorator) {
          final decorator = route.module as GuardModuleDecorator;
          for (final guard in decorator.guards) {
            final redirect = await guard(context, state);
            if (redirect != null) return redirect;
          }
        }
        return null;
      },
      builder:
          (context, state) => _safe(
            state: state,
            label: 'ModuleRoute',
            build: () => child.child(context, state),
          ),
    );
  }

  static ShellRoute _shell(ShellModuleRoute route) {
    final inner = fromAll(route.routes);

    return ShellRoute(
      routes: inner,
      observers: route.observers,
      navigatorKey: route.navigatorKey,
      parentNavigatorKey: route.parentNavigatorKey,
      builder: (context, state, child) => route.builder!(context, state, child),
      pageBuilder:
          route.pageBuilder == null
              ? null
              : (context, state, child) => _safe(
                state: state,
                label: 'ShellRoute.pageBuilder',
                build: () => route.pageBuilder!(context, state, child),
              ),
    );
  }

  static StatefulShellRoute _statefulShell(StatefulShellModuleRoute route) {
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
                GoRoute(
                  name: child.name ?? 'branch_$index',
                  path: child.path!.isEmpty ? '/' : child.path!,
                  redirect: (context, state) async {
                    for (final guard in child.guards) {
                      final redirect = await guard(context, state);
                      if (redirect != null) return redirect;
                    }
                    return null;
                  },
                  builder:
                      (context, state) => _safe(
                        state: state,
                        label: 'StatefulShell.Child',
                        build: () => child.child(context, state),
                      ),
                  pageBuilder:
                      child.pageBuilder == null
                          ? (context, state) =>
                              _transition(context, state, child)
                          : (context, state) => _safe(
                            state: state,
                            label: 'StatefulShell.Page',
                            build: () => child.pageBuilder!(context, state),
                          ),
                ),
              ],
            );
          }

          throw UnsupportedError(
            'Unsupported route type in StatefulShellModuleRoute: ${child.runtimeType}',
          );
        }).toList();

    return StatefulShellRoute.indexedStack(
      key: route.key,
      branches: branches,
      builder: route.builder,
      parentNavigatorKey: route.parentNavigatorKey,
    );
  }

  static T _safe<T>({
    required String label,
    required T Function() build,
    required GoRouterState state,
  }) {
    try {
      return build();
    } catch (e, s) {
      Logger.error('Error building $label for ${state.uri}: $e\n$s');
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
      final value = CompilerRoute(path);
      Logger.navigation('Valid path: ${value.pattern}');
    } catch (e) {
      Logger.error('Invalid path in $type: $path → $e');
      throw ArgumentError.value(path, 'path', 'Invalid path syntax in $type');
    }
  }
}
