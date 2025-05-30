import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/manager.dart';
import 'package:go_router/go_router.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/transitions/transition.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

abstract class Module {
  List<Module> get imports => const [];
  List<Bind<Object>> get binds => const [];
  List<ModuleInterface> get routes => const [];

  final _routerManager = Manager();

  List<RouteBase> configureRoutes({
    bool topLevel = false,
    String modulePath = '',
  }) {
    List<RouteBase> result = [];
    _routerManager.registerBindsAppModule(this);

    result.addAll(_createShellRoutes(topLevel));
    result.addAll(_createChildRoutes(topLevel: topLevel));
    result.addAll(
      _createModuleRoutes(topLevel: topLevel, modulePath: modulePath),
    );

    return result;
  }

  GoRoute _createChild({
    required bool topLevel,
    required ChildRoute childRoute,
  }) => GoRoute(
    name: childRoute.name,
    redirect: childRoute.redirect,
    parentNavigatorKey: childRoute.parentNavigatorKey,
    path: _normalizePath(path: childRoute.path, topLevel: topLevel),
    builder:
        (context, state) =>
            _buildRouteChild(context, state: state, route: childRoute),
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

  List<GoRoute> _createChildRoutes({required bool topLevel}) =>
      routes
          .whereType<ChildRoute>()
          .where((route) => adjustRoute(route.path) != '/')
          .map((route) => _createChild(childRoute: route, topLevel: topLevel))
          .toList();

  GoRoute _createModule({
    required bool topLevel,
    required String modulePath,
    required ModuleRoute module,
  }) {
    final childRoute =
        module.module.routes
            .whereType<ChildRoute>()
            .where((route) => adjustRoute(route.path) == '/')
            .firstOrNull;

    return GoRoute(
      redirect: childRoute?.redirect,
      name: childRoute?.name ?? module.name,
      parentNavigatorKey: childRoute?.parentNavigatorKey,
      builder:
          (context, state) => _buildModuleChild(
            context,
            state: state,
            module: module,
            route: childRoute,
          ),
      routes: module.module.configureRoutes(
        modulePath: module.path,
        topLevel: false,
      ),
      path: _normalizePath(
        path: module.path + (childRoute?.path ?? ''),
        topLevel: topLevel,
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
  }) =>
      routes
          .whereType<ModuleRoute>()
          .map(
            (module) => _createModule(
              module: module,
              topLevel: topLevel,
              modulePath: modulePath,
            ),
          )
          .toList();

  List<RouteBase> _createShellRoutes(bool topLevel) =>
      routes.whereType<ShellModuleRoute>().map((shellRoute) {
        if (shellRoute.routes
            .whereType<ChildRoute>()
            .where((element) => element.path == '/')
            .isNotEmpty) {
          throw Exception(
            'ShellModularRoute cannot contain ChildRoute with path /',
          );
        }

        return ShellRoute(
          redirect: shellRoute.redirect,
          observers: shellRoute.observers,
          navigatorKey: shellRoute.navigatorKey,
          parentNavigatorKey: shellRoute.parentNavigatorKey,
          restorationScopeId: shellRoute.restorationScopeId,
          builder:
              (context, state, child) =>
                  shellRoute.builder!(context, state, child),
          pageBuilder:
              shellRoute.pageBuilder != null
                  ? (context, state, child) =>
                      shellRoute.pageBuilder!(context, state, child)
                  : null,
          routes:
              shellRoute.routes
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
                        modulePath: routeOrModule.path,
                      );
                    }

                    return null;
                  })
                  .whereType<RouteBase>()
                  .toList(),
        );
      }).toList();

  String adjustRoute(String route) =>
      (route == '/' || route.startsWith('/:')) ? '/' : route;

  String _normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith('/') && !topLevel && !path.startsWith('/:')) {
      path = path.substring(1);
    }

    return buildPath(path);
  }

  String buildPath(String path) {
    if (!path.endsWith('/')) path = '$path/';

    path = path.replaceAll(RegExp(r'/+'), '/');

    if (path == '/') return path;

    return path.substring(0, path.length - 1);
  }

  Widget _buildRouteChild(
    BuildContext context, {
    required ChildRoute route,
    required GoRouterState state,
  }) {
    _register(path: state.uri.toString());
    return route.child(context, state);
  }

  Page<void> _buildCustomTransitionPage(
    BuildContext context, {
    required ChildRoute route,
    required GoRouterState state,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: route.child(context, state),
    transitionsBuilder: Transition.builder(
      config: () => _register(path: state.uri.toString()),
      type: route.transition ?? Modugo.getDefaultPageTransition,
    ),
  );

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
    final completer = Completer<bool>();
    final onExit = route.onExit?.call(context, state) ?? Future.value(true);

    completer.complete(onExit);

    return completer.future.then((exit) {
      try {
        if (exit) _unregister(state.uri.toString(), module: module);
        return exit;
      } catch (_) {
        return false;
      }
    });
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
