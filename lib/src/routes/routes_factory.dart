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
          break;

        case AliasRoute():
          final allRoutes = routes.whereType<ChildRoute>().firstWhere(
            (child) => child.path == route.to,
            orElse:
                () =>
                    throw ArgumentError(
                      'Alias ​​Route "${route.from}" points to "${route.to}", but there is no corresponding Child Route.',
                    ),
          );
          childs.add(_createAlias(route, allRoutes));
          break;

        case ModuleRoute():
          final module = _createModule(route);
          if (module != null) modules.add(module);
          break;

        case ShellModuleRoute():
          shells.add(_createShell(route));
          break;

        case StatefulShellModuleRoute():
          shells.add(_createStatefulShell(route));
          break;

        default:
          throw UnsupportedError('Unsupported route type: $route');
      }
    }

    return [...shells, ...childs, ...modules];
  }

  static GoRoute _createChild(ChildRoute route) {
    _validatePath(route.path!, 'ChildRoute');

    return GoRoute(
      path: route.path!,
      name: route.name,
      parentNavigatorKey: route.parentNavigatorKey,
      redirect: (context, state) async {
        for (final guard in route.guards) {
          final redirect = await guard(context, state);
          if (redirect != null) return redirect;
        }
        return null;
      },
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

  static GoRoute _createAlias(AliasRoute alias, ChildRoute target) {
    _validatePath(alias.from, 'AliasRoute');

    return GoRoute(
      path: alias.from,
      redirect: (context, state) async {
        for (final guard in target.guards) {
          final redirect = await guard(context, state);
          if (redirect != null) return redirect;
        }
        return null;
      },
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

  static GoRoute? _createModule(ModuleRoute route) {
    final module = route.module;
    final first = module.routes().whereType<ChildRoute>().firstOrNull;

    if (first == null) return null;

    _validatePath(first.path!, 'ModuleRoute');

    return GoRoute(
      name: route.name,
      path: route.path!,
      routes: module.configureRoutes(),
      parentNavigatorKey: route.parentNavigatorKey ?? first.parentNavigatorKey,
      redirect: (context, state) async {
        if (module is GuardModuleDecorator) {
          for (final guard in module.guards) {
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
      builder: (context, state, child) => route.builder!(context, state, child),
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
      builder: route.builder,
      parentNavigatorKey: route.parentNavigatorKey,
    );
  }

  static T _safe<T>({
    required String label,
    required GoRouterState state,
    required T Function() build,
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
      final compiler = CompilerRoute(path);
      Logger.navigation('Valid path: ${compiler.pattern}');
    } catch (e) {
      Logger.error('Invalid path in $type: $path → $e');
      throw ArgumentError.value(path, 'path', 'Invalid syntax in $type: $e');
    }
  }
}
