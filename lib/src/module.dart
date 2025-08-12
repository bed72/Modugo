// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/transition.dart';
import 'package:modugo/src/managers/injector_manager.dart';

import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
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
  final _routerManager = InjectorManager();

  /// If true, this module will not have its dependencies automatically disposed.
  ///
  /// Useful for persistent modules like tabs in a bottom navigation bar.
  ///
  /// Defaults to false.
  bool get persistent => false;

  /// List of navigation routes this module exposes.
  ///
  /// Routes can be [ChildRoute], [ModuleRoute], [ShellModuleRoute], etc.
  ///
  /// Defaults to an empty list.
  List<IModule> routes() => const [];

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
  FutureOr<void> binds(IInjector i) {}

  /// List of imported modules that this module depends on.
  ///
  /// Allows modular composition by importing submodules.
  ///
  /// Defaults to an empty list.
  FutureOr<List<Module>> imports() => const [];

  /// Called before routes are configured.
  /// Registers binds and awaits async resolution.
  Future<void> ensureInitialized() async {
    await binds(_routerManager.injector);
    await _routerManager.injector.ensureInitialized();
  }

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
    if (!_routerManager.isModuleActive(this)) {
      _routerManager.registerBindsAppModule(this);
    }

    final childRoutes = _createChildRoutes();
    final shellRoutes = _createShellRoutes(topLevel);
    final moduleRoutes = _createModuleRoutes(topLevel);

    final paths = [
      ...shellRoutes,
      ...childRoutes,
      ...moduleRoutes,
    ].whereType<GoRoute>().map((r) => r.path);

    Logger.navigation(
      'Final recorded routes: ${paths.isEmpty ? "(/) or ('')" : "$paths"}',
    );

    return [...shellRoutes, ...childRoutes, ...moduleRoutes];
  }

  GoRoute _createChild({
    required String effectivePath,
    required ChildRoute childRoute,
  }) {
    _validPath(childRoute.path!, 'ChildRoute');

    return GoRoute(
      path: effectivePath,
      name: childRoute.name,
      parentNavigatorKey: childRoute.parentNavigatorKey,
      redirect: (context, state) async {
        for (final guard in childRoute.guards) {
          final result = await guard.call(context, state);
          if (result != null) return result;
        }

        if (childRoute.redirect != null) {
          return await childRoute.redirect!(context, state);
        }

        return null;
      },
      builder: (context, state) {
        try {
          _register(path: state.uri.toString());

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
              ? (context, state) => _safePageBuilder(
                state: state,
                label: 'child page',
                build: () => childRoute.pageBuilder!(context, state),
              )
              : (context, state) => _buildCustomTransitionPage(
                context,
                state: state,
                route: childRoute,
              ),
    );
  }

  List<GoRoute> _createChildRoutes() =>
      routes()
          .whereType<ChildRoute>()
          .map(
            (route) =>
                _createChild(effectivePath: route.path!, childRoute: route),
          )
          .toList();

  GoRoute _createModule({required ModuleRoute module, required bool topLevel}) {
    final childRoute =
        module.module
            .routes()
            .whereType<ChildRoute>()
            .where((route) => _adjustRoute(route.path!) == '/')
            .firstOrNull;

    if (childRoute != null) _validPath(childRoute.path!, 'ModuleRoute');

    return GoRoute(
      path: module.path!,
      routes: module.module.configureRoutes(topLevel: false),
      name: module.name?.isNotEmpty == true ? module.name : null,
      parentNavigatorKey:
          module.parentNavigatorKey ?? childRoute?.parentNavigatorKey,
      builder:
          (context, state) => _buildModuleChild(
            context,
            state: state,
            module: module,
            route: childRoute,
          ),
      redirect: (context, state) async {
        if (module.redirect != null) {
          final result = module.redirect!(context, state);
          if (result != null) return result;
        }

        if (childRoute?.redirect != null) {
          return await childRoute!.redirect!(context, state);
        }

        return null;
      },
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

  List<GoRoute> _createModuleRoutes(bool topLevel) =>
      routes()
          .whereType<ModuleRoute>()
          .map((module) => _createModule(module: module, topLevel: topLevel))
          .toList();

  List<RouteBase> _createShellRoutes(bool topLevel) {
    final shellRoutes = <RouteBase>[];

    for (final route in routes()) {
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
            }
          }
        }

        final innerRoutes =
            route.routes
                .map((routeOrModule) {
                  if (routeOrModule is ChildRoute) {
                    _validPath(routeOrModule.path!, 'ShellModuleRoute');

                    return _createChild(
                      childRoute: routeOrModule,
                      effectivePath: routeOrModule.path!,
                    );
                  }

                  if (routeOrModule is ModuleRoute) {
                    return _createModule(
                      topLevel: topLevel,
                      module: routeOrModule,
                    );
                  }

                  return null;
                })
                .whereType<RouteBase>()
                .toList();

        shellRoutes.add(
          ShellRoute(
            routes: innerRoutes,
            observers: route.observers,
            navigatorKey: route.navigatorKey,
            parentNavigatorKey: route.parentNavigatorKey,
            restorationScopeId: route.restorationScopeId,
            builder:
                (context, state, child) =>
                    route.builder!(context, state, child),
            redirect: (context, state) async {
              if (route.redirect != null) {
                return await route.redirect!(context, state);
              }

              return null;
            },
            pageBuilder:
                route.pageBuilder != null
                    ? (context, state, child) => _safePageBuilder(
                      state: state,
                      label: 'shell page',
                      build: () => route.pageBuilder!(context, state, child),
                    )
                    : null,
          ),
        );
      }

      if (route is StatefulShellModuleRoute) {
        shellRoutes.add(route.toRoute(topLevel: topLevel, path: '/'));
      }
    }

    return shellRoutes;
  }

  T _safePageBuilder<T>({
    required String label,
    required GoRouterState state,
    required T Function() build,
  }) {
    try {
      _register(path: state.uri.toString());
      return build();
    } catch (e, s) {
      _unregister(state.uri.toString());
      Logger.error('Error building $label for ${state.uri}: $e\n$s');
      rethrow;
    }
  }

  String _adjustRoute(String route) =>
      (route == '/' || route.startsWith('/:')) ? '/' : route;

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
