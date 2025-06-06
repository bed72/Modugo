import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

abstract class Module {
  List<Bind> get binds => const [];
  List<Module> get imports => const [];
  List<ModuleInterface> get routes => const [];

  final _routerManager = Manager();

  List<RouteBase> configureRoutes({bool topLevel = false, String path = ''}) {
    if (!_routerManager.isModuleActive(this)) {
      _routerManager.registerBindsAppModule(this);
    }

    final childRoutes = _createChildRoutes(topLevel);
    final shellRoutes = _createShellRoutes(topLevel, path);
    final moduleRoutes = _createModuleRoutes(
      modulePath: path,
      topLevel: topLevel,
    );

    if (Modugo.debugLogDiagnostics) {
      final paths = [
        ...shellRoutes,
        ...childRoutes,
        ...moduleRoutes,
      ].whereType<GoRoute>().map((r) => r.path);

      ModugoLogger.info(
        '🛤️  Final recorded routes: ${paths.isEmpty ? "(/) or ('')" : "$paths"}',
      );
    }

    return [...shellRoutes, ...childRoutes, ...moduleRoutes];
  }

  GoRoute _createChild({
    required bool topLevel,
    required ChildRoute childRoute,
  }) => GoRoute(
    name: childRoute.name,
    redirect: childRoute.redirect,
    parentNavigatorKey: childRoute.parentNavigatorKey,
    path: _normalizePath(path: childRoute.path, topLevel: topLevel),
    builder: (context, state) {
      try {
        _register(path: state.uri.toString());

        if (Modugo.debugLogDiagnostics) {
          ModugoLogger.info('📦 ModuleRoute → ${state.uri}');
        }

        return childRoute.child(context, state);
      } catch (e, s) {
        _unregister(state.uri.toString());
        if (Modugo.debugLogDiagnostics) {
          ModugoLogger.error('Error building route ${state.uri}: $e\n$s');
        }
        rethrow;
      }
    },
    onExit:
        (context, state) => _handleRouteExit(
          context,
          module: this,
          state: state,
          route: childRoute,
        ),
    pageBuilder:
        childRoute.pageBuilder != null
            ? (context, state) => childRoute.pageBuilder!(context, state)
            : (context, state) => _buildCustomTransitionPage(
              context,
              state: state,
              route: childRoute,
            ),
  );

  List<GoRoute> _createChildRoutes(bool topLevel) =>
      routes
          .whereType<ChildRoute>()
          .where((route) => topLevel || _adjustRoute(route.path) != '/')
          .map((route) => _createChild(childRoute: route, topLevel: topLevel))
          .toList();

  GoRoute _createModule({
    required String path,
    required bool topLevel,
    required ModuleRoute module,
  }) {
    final childRoute =
        module.module.routes
            .whereType<ChildRoute>()
            .where((route) => _adjustRoute(route.path) == '/')
            .firstOrNull;

    return GoRoute(
      name: childRoute?.name ?? module.name,
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      redirect:
          (context, state) =>
              module.redirect?.call(context, state) ??
              childRoute?.redirect?.call(context, state),
      builder:
          (context, state) => _buildModuleChild(
            context,
            state: state,
            module: module,
            route: childRoute,
          ),
      routes: module.module.configureRoutes(topLevel: false, path: module.path),
      path: _normalizePath(
        topLevel: topLevel,
        path: module.path + (childRoute?.path ?? ''),
      ),
      onExit:
          (context, state) =>
              childRoute == null
                  ? Future.value(true)
                  : _handleRouteExit(
                    context,
                    state: state,
                    route: childRoute,
                    module: module.module,
                  ),
    );
  }

  List<GoRoute> _createModuleRoutes({
    required bool topLevel,
    required String modulePath,
  }) => routes
      .whereType<ModuleRoute>()
      .map(
        (module) =>
            _createModule(module: module, topLevel: topLevel, path: modulePath),
      )
      .toList(growable: false);

  List<RouteBase> _createShellRoutes(bool topLevel, String path) {
    final shellRoutes = <RouteBase>[];

    for (final route in routes) {
      if (route is ShellModuleRoute) {
        if (route.binds.isNotEmpty) {
          for (final bind in route.binds) {
            final existing = Bind.getBindByType(bind.type);
            if (existing == null) {
              Bind.register(bind);

              if (Modugo.debugLogDiagnostics) {
                ModugoLogger.injection('🔐 ShellBind → ${bind.type}');
              }
            }
          }
        }

        if (route.routes.whereType<ChildRoute>().any((r) => r.path == '/')) {
          if (Modugo.debugLogDiagnostics) {
            ModugoLogger.warn(
              '⚠️ Shell ModuleRoute contains Child Route with path "/". Make sure this is the only root route.',
            );
          }
        }

        final innerRoutes =
            route.routes
                .map((routeOrModule) {
                  if (routeOrModule is ChildRoute) {
                    return _createChild(
                      topLevel: topLevel,
                      childRoute: routeOrModule,
                    );
                  }

                  if (routeOrModule is ModuleRoute) {
                    return _createModule(
                      topLevel: topLevel,
                      module: routeOrModule,
                      path: routeOrModule.path,
                    );
                  }

                  return null;
                })
                .whereType<RouteBase>()
                .toList();

        shellRoutes.add(
          ShellRoute(
            redirect: route.redirect,
            observers: route.observers,
            navigatorKey: route.navigatorKey,
            parentNavigatorKey: route.parentNavigatorKey,
            restorationScopeId: route.restorationScopeId,
            builder: (context, state, child) {
              if (Modugo.debugLogDiagnostics) {
                ModugoLogger.info('🧩 ShellRoute → \${state.uri}');
              }
              return route.builder!(context, state, child);
            },
            pageBuilder:
                route.pageBuilder != null
                    ? (context, state, child) =>
                        route.pageBuilder!(context, state, child)
                    : null,
            routes: innerRoutes,
          ),
        );
      }

      if (route is StatefulShellModuleRoute) {
        shellRoutes.add(route.toRoute(topLevel: topLevel, path: path));

        if (Modugo.debugLogDiagnostics) {
          ModugoLogger.info('🧩 StatefulShellModuleRoute registrada.');
        }
      }
    }

    return shellRoutes;
  }

  String _adjustRoute(String route) =>
      (route == '/' || route.startsWith('/:')) ? '/' : route;

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith('/') && !topLevel && !path.startsWith('/:')) {
      path = path.substring(1);
    }

    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');

    return path == '/' ? path : path.substring(0, path.length - 1);
  }

  Page<void> _buildCustomTransitionPage(
    BuildContext context, {
    required ChildRoute route,
    required GoRouterState state,
  }) {
    _register(path: state.uri.toString());

    return CustomTransitionPage(
      key: state.pageKey,
      child: route.child(context, state),
      transitionsBuilder: Transition.builder(
        config: () {},
        type: route.transition ?? Modugo.getDefaultTransition,
      ),
    );
  }

  Widget _buildModuleChild(
    BuildContext context, {
    required ModuleRoute module,
    required GoRouterState state,
    ChildRoute? route,
  }) {
    _register(path: state.uri.toString(), module: module.module);
    return route?.child(context, state) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(
    BuildContext context, {
    required Module module,
    required ChildRoute route,
    required GoRouterState state,
  }) {
    final onExit = route.onExit?.call(context, state);

    final futureExit =
        onExit is Future<bool> ? onExit : Future.value(onExit ?? true);

    return futureExit
        .then((exit) {
          try {
            if (exit) _unregister(state.uri.toString(), module: module);
            return exit;
          } catch (_) {
            return false;
          }
        })
        .catchError((_) => false);
  }

  void _register({required String path, Module? module}) {
    _routerManager.registerBindsIfNeeded(module ?? this);
    if (path == '/') return;
    _routerManager.registerRoute(path, module ?? this);
  }

  void _unregister(String path, {Module? module}) {
    _routerManager.unregisterRoute(path, module ?? this);
  }
}
