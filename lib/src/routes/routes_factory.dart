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

  /// Builds all [RouteBase]s for the given list of [IRoute]s.
  ///
  /// Handles aliases, shells, and nested modules in a single pass.
  static List<RouteBase> from(List<IRoute> routes) =>
      routes.expand((route) => _from(route, routes)).toList();

  /// Builds one or more [RouteBase]s from a single [IRoute].
  ///
  /// This allows returning multiple routes (e.g. for alias sets).
  static List<RouteBase> _from(IRoute route, List<IRoute> routes) {
    switch (route) {
      case ChildRoute():
        return [_child(route)];

      case ModuleRoute():
        return [_module(route)];

      case ShellModuleRoute():
        return [_shell(route)];

      case StatefulShellModuleRoute():
        return [_statefulShell(route)];

      case AliasRoute():
        return [_alias(route, routes)];

      default:
        throw UnsupportedError('Unsupported route type: $route');
    }
  }

  static GoRoute _child(ChildRoute route) {
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

  static GoRoute _alias(AliasRoute alias, List<IRoute> contextRoutes) {
    final target = contextRoutes.whereType<ChildRoute>().firstWhere(
      (child) => child.path == alias.to,
      orElse:
          () =>
              throw ArgumentError(
                'AliasRoute "${alias.from}" points to missing target "${alias.to}".',
              ),
    );

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

  static GoRoute _module(ModuleRoute route) {
    final child = route.module.routes().whereType<ChildRoute>().firstOrNull;

    if (child == null) {
      return GoRoute(path: route.path!, builder: (_, __) => const SizedBox());
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
    final routes = from(route.routes);

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
                label: 'ShellRoute',
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
                _child(
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
