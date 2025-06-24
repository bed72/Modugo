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
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Abstract base class representing a modular feature or logical section of the app.
///
/// Each [Module] defines:
/// - a list of imported modules ([imports]) to compose complex module trees
/// - a list of routes ([routes]) it exposes for navigation
/// - a list of dependency injection binds ([binds]) it manages
///
/// The [_modulePath] stores the base path prefix used internally during route configuration.
///
/// Example usage:
/// ```dart
/// class HomeModule extends Module {
///   @override
///   List<Module> get imports => [SharedModule()];
///
///   @override
///   List<IModule> get routes => [ChildRoute('/', child: (c, s) => HomePage())];
///
///   @override
///   List<void Function(IInjector)> get binds => [
///     (injector) => injector.addSingleton((i) => HomeController()),
///   ];
/// }
/// ```
abstract class Module {
  late String _modulePath;

  /// List of imported modules that this module depends on.
  ///
  /// Allows modular composition by importing submodules.
  ///
  /// Defaults to an empty list.
  List<Module> get imports => const [];

  /// List of navigation routes this module exposes.
  ///
  /// Routes can be [ChildRoute], [ModuleRoute], [ShellModuleRoute], etc.
  ///
  /// Defaults to an empty list.
  List<IModule> get routes => const [];

  /// Registers all dependency injection bindings for this module.
  ///
  /// Override this method to declare your dependencies using the [IInjector].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void binds(IInjector i) {
  ///   i
  ///     ..addSingleton<A>(() => A())
  ///     ..addLazySingleton<B>(() => B());
  /// }
  /// ```
  void binds(IInjector i) {}

  final _routerManager = Manager();

  /// Configures and returns the list of [RouteBase]s defined by this module.
  ///
  /// This method is responsible for:
  /// - registering binds for the module (if not already active)
  /// - creating and combining child, shell, and module routes
  /// - optionally logging the final set of registered route paths when diagnostics are enabled
  ///
  /// Parameters:
  /// - [topLevel]: indicates if this module is the root module (default: false)
  /// - [path]: base path prefix to apply to all routes in this module (default: empty)
  ///
  /// Returns a combined list of all routes defined by this module and its nested structures.
  ///
  /// Example:
  /// ```dart
  /// final routes = myModule.configureRoutes(topLevel: true, path: '/app');
  /// ```
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

    final paths = [
      ...shellRoutes,
      ...childRoutes,
      ...moduleRoutes,
    ].whereType<GoRoute>().map((r) => r.path);

    Logger.info(
      'Final recorded routes: ${paths.isEmpty ? "(/) or ('')" : "$paths"}',
    );

    return [...shellRoutes, ...childRoutes, ...moduleRoutes];
  }

  GoRoute _createChild({
    required bool topLevel,
    required String effectivePath,
    required ChildRoute childRoute,
  }) {
    _validPath(childRoute.path, 'ChildRoute');

    return GoRoute(
      path: effectivePath,
      name: childRoute.name,
      redirect: childRoute.redirect,
      parentNavigatorKey: childRoute.parentNavigatorKey,
      builder: (context, state) {
        try {
          _register(path: state.uri.toString());

          Logger.info('[MODULE ROUTE] ${state.uri}');
          Logger.info(
            '[GO ROUTER] path for ${childRoute.name}: $effectivePath',
          );

          return childRoute.child(context, state);
        } catch (e, s) {
          _unregister(state.uri.toString());

          Logger.error('Error building route ${state.uri}: $e\n$s');

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
  }

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

    if (childRoute != null) _validPath(childRoute.path, 'ModuleRoute');

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
      onExit: (context, state) {
        if (childRoute == null) return Future.value(true);

        return _handleRouteExit(
          context,
          state: state,
          route: childRoute,
          branch: module.path,
          module: module.module,
        );
      },
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
            final before = Injector().registeredTypes;
            bind(Injector());
            final after = Injector().registeredTypes;

            final newTypes = after.difference(before);
            for (final type in newTypes) {
              _routerManager.bindReferences[type] =
                  (_routerManager.bindReferences[type] ?? 0) + 1;

              Logger.injection('[SHELL BIND]: $type');
            }
          }
        }

        final innerRoutes =
            route.routes
                .map((routeOrModule) {
                  if (routeOrModule is ChildRoute) {
                    _validPath(routeOrModule.path, 'ShellModuleRoute');

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
              Logger.info('[SHELL ROUTE]: ${state.uri}');

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

        Logger.info(
          '[STATEFUL SHELL MODULE ROUTE] registered with ${route.routes.length} branches.',
        );
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

  void _validPath(String path, String type) {
    try {
      CompilerRoute(path);
    } catch (e) {
      Logger.error('Invalid path in $type: $path → $e');

      throw ArgumentError.value(
        path,
        'ChildRoute.path',
        'Invalid path syntax in $type: $e',
      );
    }
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
