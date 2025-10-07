import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Factory responsible for converting [IRoute] instances into [RouteBase] objects.
///
/// It centralizes the construction logic for:
/// - [ChildRoute]
/// - [ModuleRoute]
/// - [ShellModuleRoute]
/// - [StatefulShellModuleRoute]
///
/// Ensures guards, transitions, and validation are consistently applied.
final class RoutesFactory {
  const RoutesFactory._();

  /// Builds a [RouteBase] instance from the given [route].
  static RouteBase from(IRoute route) {
    switch (route) {
      case ChildRoute():
        return _child(route);

      case ModuleRoute():
        return _module(route);

      case ShellModuleRoute():
        return _shell(route);

      case StatefulShellModuleRoute():
        return _statefulShell(route);

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
          final value = await guard(context, state);
          if (value != null) return value;
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

  static GoRoute _module(ModuleRoute route) {
    final child = route.module.routes().whereType<ChildRoute>().firstOrNull;
    if (child == null) {
      return GoRoute(
        path: route.path!,
        builder: (_, _) => const SizedBox.shrink(),
      );
    }

    _validatePath(child.path!, 'ModuleRoute');

    return GoRoute(
      path: route.path!,
      name: route.name,
      parentNavigatorKey: route.parentNavigatorKey ?? child.parentNavigatorKey,
      routes: route.module.configureRoutes(),
      redirect: (context, state) async {
        if (route.module is GuardModuleDecorator) {
          final decorator = route.module as GuardModuleDecorator;
          for (final guard in decorator.guards) {
            final value = await guard(context, state);
            if (value != null) return value;
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
    final innerRoutes = route.routes.map(RoutesFactory.from).toList();

    return ShellRoute(
      routes: innerRoutes,
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
              navigatorKey: child.parentNavigatorKey,
              routes: child.module.configureRoutes(),
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
                      final value = await guard(context, state);
                      if (value != null) return value;
                    }
                    return null;
                  },
                  builder:
                      (context, state) => _safe(
                        state: state,
                        label: 'StatefulShellBuilder',
                        build: () => child.child(context, state),
                      ),
                  pageBuilder:
                      child.pageBuilder == null
                          ? (context, state) =>
                              _transition(context, state, child)
                          : (context, state) => _safe(
                            state: state,
                            label: 'StatefulShellPageBuilder',
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
    } catch (exception, condition) {
      Logger.error(
        'Error building $label for ${state.uri}: $exception\n$condition',
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
      final value = CompilerRoute(path);
      Logger.navigation('Valid path: ${value.pattern}');
    } catch (exception) {
      Logger.error('Invalid path in $type: $path → $exception');

      throw ArgumentError.value(
        path,
        'path',
        'Invalid path syntax in $type: $exception',
      );
    }
  }
}
