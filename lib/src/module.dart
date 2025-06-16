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

  late String _modulePath;

  final _routerManager = Manager();

  List<RouteBase> configureRoutes({bool topLevel = false, String path = ''}) {
    _modulePath = path;

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
        '🧭  Final recorded routes: ${paths.isEmpty ? "(/) or ('')" : "$paths"}',
      );
    }

    return [...shellRoutes, ...childRoutes, ...moduleRoutes];
  }

  GoRoute _createChild({
    required bool topLevel,
    required String effectivePath,
    required ChildRoute childRoute,
  }) => GoRoute(
    path: effectivePath,
    name: childRoute.name,
    redirect: childRoute.redirect,
    parentNavigatorKey: childRoute.parentNavigatorKey,
    builder: (context, state) {
      try {
        _register(path: state.uri.toString());

        if (Modugo.debugLogDiagnostics) {
          ModugoLogger.info('📦 ModuleRoute → ${state.uri}');
          ModugoLogger.info(
            '🛠 GoRoute path for ${childRoute.name}: $effectivePath',
          );
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
      routes.whereType<ChildRoute>().map((route) {
        final composedPath =
            topLevel
                ? _normalizePath(
                  topLevel: topLevel,
                  path: _composePath(_modulePath, route.path),
                )
                : route.path;

        return _createChild(
          childRoute: route,
          topLevel: topLevel,
          effectivePath: composedPath,
        );
      }).toList();

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
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      name: module.name?.isNotEmpty == true ? module.name : null,
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
        path: _normalizePath(
          topLevel: topLevel,
          path: _composePath(path, module.path + (childRoute?.path ?? '')),
        ),
      ),
      onExit:
          (context, state) =>
              childRoute == null
                  ? Future.value(true)
                  : _handleRouteExit(
                    context,
                    state: state,
                    route: childRoute,
                    branch: module.path,
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
              '🧭 Shell ModuleRoute contains Child Route with path "/". Make sure this is the only root route.',
            );
          }
        }

        final innerRoutes =
            route.routes
                .map((routeOrModule) {
                  if (routeOrModule is ChildRoute) {
                    final composedPath = _normalizePath(
                      topLevel: topLevel,
                      path: _composePath(path, routeOrModule.path),
                    );

                    return _createChild(
                      topLevel: topLevel,
                      childRoute: routeOrModule,
                      effectivePath: composedPath,
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
                ModugoLogger.info('🧭 ShellRoute → ${state.uri}');
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
        final normalizedPath = _normalizePath(path: path, topLevel: topLevel);
        shellRoutes.add(
          route.toRoute(topLevel: topLevel, path: normalizedPath),
        );

        if (Modugo.debugLogDiagnostics) {
          ModugoLogger.info(
            '🧭 StatefulShellModuleRoute registered with ${route.routes.length} branches.',
          );
        }
      }
    }

    return shellRoutes;
  }

  String _adjustRoute(String route) =>
      (route == '/' || route.startsWith('/:')) ? '/' : route;

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.trim().isEmpty) return '/';

    if (path.startsWith('/') && !topLevel && !path.startsWith('/:')) {
      path = path.substring(1);
    }

    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');

    return path == '/' ? path : path.substring(0, path.length - 1);
  }

  String _composePath(String base, String sub) {
    final b = base.trim().replaceAll(RegExp(r'^/+|/+\$'), '');
    final s = sub.trim().replaceAll(RegExp(r'^/+|/+\$'), '');

    if (b.isEmpty && s.isEmpty) return '/';

    final composed = [b, s].where((p) => p.isNotEmpty).join('/');
    return '/${composed.replaceAll(RegExp(r'/+'), '/')}';
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
    _register(
      branch: module.path,
      module: module.module,
      path: state.uri.toString(),
    );
    return route?.child(context, state) ?? Container();
  }

  FutureOr<bool> _handleRouteExit(
    BuildContext context, {
    required Module module,
    required ChildRoute route,
    required GoRouterState state,
    String? branch,
  }) {
    final onExit = route.onExit?.call(context, state);

    final futureExit =
        onExit is Future<bool> ? onExit : Future.value(onExit ?? true);

    return futureExit
        .then((exit) {
          try {
            if (exit) {
              _unregister(state.uri.toString(), module: module, branch: branch);
            }
            return exit;
          } catch (_) {
            return false;
          }
        })
        .catchError((_) => false);
  }

  void _register({required String path, Module? module, String? branch}) {
    _routerManager.registerBindsIfNeeded(module ?? this);
    if (path == '/') return;
    _routerManager.registerRoute(path, module ?? this, branch: branch);
  }

  void _unregister(String path, {Module? module, String? branch}) {
    _routerManager.unregisterRoute(path, module ?? this, branch: branch);
  }
}
