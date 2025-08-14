// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// A set of module types that have been registered globally,
/// used to ensure the same module is not bound more than once.
final Set<Type> _modulesRegistered = {};

/// Abstract base class for a "module" (feature) within the application.
///
/// A [Module] defines:
/// - [imports()]: other modules it depends on. The `binds()` of imported
///   modules are executed before the current module's `binds()`.
/// - [routes()]: the route tree exposed by this module (e.g., [ChildRoute],
///   [ModuleRoute], [ShellModuleRoute], [StatefulShellModuleRoute]).
/// - [binds()]: registers the module's dependencies in [GetIt] (via [i]).
///
/// Behavior:
/// - When [configureRoutes()] is called, the framework registers — **only once
///   per module type** — the `binds()` of the current module **and** all
///   imported modules, then sets up the route list.
/// - Dependency registration is idempotent: if a module has already been
///   registered, its `binds()` will not be executed again.
/// - Even if a module does not expose its own routes, if it appears in
///   [imports()], its `binds()` will still be executed.
///
/// Customization:
/// - Override [persistent] to keep the module's dependencies alive even when
///   there are no active routes for it.
/// - Use [initState()] and [dispose()] to manage the module's internal state if
///   necessary.
/// - The injection instance is accessible via [i] (shortcut to
///   `GetIt.instance`).
///
/// Example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   List<Module> imports() => [SharedModule()];
///
///   @override
///   List<IModule> routes() => [
///     ChildRoute(path: '/', child: (context, state) => const HomePage()),
///   ];
///
///   @override
///   void binds() {
///     i
///       ..registerLazySingleton<HomeController>(() => HomeController())
///       ..registerSingleton<ApiClient>(ApiClient());
///   }
/// }
/// ```
abstract class Module {
  /// Centralized Modugo dependency and route manager instance.
  /// Handles bind registration, module lifecycle, and route configuration.
  final _manager = Manager();

  /// Shortcut to access the global GetIt instance used for dependency injection.
  /// Provides direct access to registered services and singletons.
  GetIt get i => GetIt.instance;

  /// Called when the module is initialized.
  ///
  /// Use this method to perform any setup required when the module
  /// becomes active, such as initializing internal state, registering
  /// listeners, or preparing resources.
  ///
  /// This method is automatically called by the framework when the
  /// module is first instantiated or when its routes become active.
  ///
  /// **Note:** Subclasses should call `super.initState()` if they
  /// override this method to ensure proper module lifecycle behavior.
  void initState() {}

  /// Called when the module is being disposed.
  ///
  /// Use this method to clean up resources, cancel subscriptions,
  /// dispose internal state, and remove any module-specific event
  /// listeners.
  ///
  /// This method is automatically called by the framework when the
  /// module is no longer needed or when its routes are removed from
  /// the navigation stack.
  ///
  /// **Important:** Subclasses should call `super.dispose()` if they
  /// override this method to ensure that all module-level resources,
  /// including event channels and subscriptions, are properly released.
  void dispose() {}

  /// Registers all dependency injection bindings for this module.
  ///
  /// Override this method to declare your dependencies using the [GetIt].
  void binds() {}

  /// List of imported modules that this module depends on.
  ///
  /// Allows modular composition by importing submodules.
  /// Defaults to an empty list.
  List<Module> imports() => const [];

  /// List of navigation routes this module exposes.
  ///
  /// Routes can be [ChildRoute], [ModuleRoute], [ShellModuleRoute], etc.
  /// Defaults to an empty list.
  List<IModule> routes() => const [];

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
  /// final routes = module.configureRoutes(topLevel: true, path: '/app');
  /// ```
  List<RouteBase> configureRoutes({bool topLevel = false, String path = '/'}) {
    _register(path: path);

    final childRoutes = _createChildRoutes();
    final shellRoutes = _createShellRoutes(topLevel);
    final moduleRoutes = _createModuleRoutes(topLevel);

    return [...shellRoutes, ...childRoutes, ...moduleRoutes];
  }

  List<GoRoute> _createModuleRoutes(bool topLevel) =>
      routes()
          .whereType<ModuleRoute>()
          .map((module) => _createModule(module: module, topLevel: topLevel))
          .toList();

  List<GoRoute> _createChildRoutes() =>
      routes()
          .whereType<ChildRoute>()
          .map(
            (route) =>
                _createChild(effectivePath: route.path!, childRoute: route),
          )
          .toList();

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

        return childRoute.redirect != null
            ? await childRoute.redirect!(context, state)
            : null;
      },
      builder: (context, state) {
        try {
          return childRoute.child(context, state);
        } catch (exception, stack) {
          Logger.error('Error building route ${state.uri}: $exception\n$stack');

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

        return childRoute?.redirect != null
            ? await childRoute!.redirect!(context, state)
            : null;
      },
      onExit: (context, state) {
        if (childRoute == null) return Future.value(true);

        return _handleRouteExit(
          context,
          state: state,
          route: childRoute,
          module: module.module,
        );
      },
    );
  }

  List<RouteBase> _createShellRoutes(bool topLevel) {
    final shellRoutes = <RouteBase>[];

    for (final route in routes()) {
      if (route is ShellModuleRoute) {
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
              return route.redirect != null
                  ? await route.redirect!(context, state)
                  : null;
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

  String _adjustRoute(String route) =>
      (route == '/' || route.startsWith('/:')) ? '/' : route;

  /// Unregisters a route path and disposes the module if it has no more active routes.
  ///
  /// [path]    The route path to unregister.
  /// [module]  Optional module instance to unregister instead of `this`.
  void _unregister(String path, {Module? module}) {
    final targetModule = module ?? this;

    _manager.unregisterRoute(path, targetModule);
    if (_manager.isModuleActive(targetModule)) dispose();
  }

  Widget _buildModuleChild(
    BuildContext context, {
    required ModuleRoute module,
    required GoRouterState state,
    ChildRoute? route,
  }) => route?.child(context, state) ?? Placeholder();

  Page<void> _buildCustomTransitionPage(
    BuildContext context, {
    required ChildRoute route,
    required GoRouterState state,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: route.child(context, state),
    transitionsBuilder: Transition.builder(
      config: () {},
      type: route.transition ?? Modugo.getDefaultTransition,
    ),
  );

  /// Validates a path for correct syntax using [CompilerRoute].
  void _validPath(String path, String type) {
    try {
      CompilerRoute(path);
    } catch (exception) {
      Logger.error('Invalid path in $type: $path → $exception');
      throw ArgumentError.value(
        path,
        'ChildRoute.path',
        'Invalid path syntax in $type: $exception',
      );
    }
  }

  T _safePageBuilder<T>({
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

  /// Handles route exit by unregistering the route from [Manager] and cleaning up
  /// the module if it has no more active routes.
  ///
  /// Ensures that:
  /// 1. The module is only unregistered when the route has fully exited.
  /// 2. All bindings are cleaned from [GetIt] if no routes remain active.
  /// 3. Any errors during exit handling do not crash the app.
  ///
  /// [context] The current [BuildContext].
  /// [module]  The module associated with the route.
  /// [route]   The [ChildRoute] that is being exited.
  /// [state]   The current [GoRouterState].
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
          if (exit) {
            _unregister(state.uri.toString(), module: module);
          }
          return exit;
        })
        .catchError((_) => false);
  }

  /// Registers a module and all its imports recursively and tracks the route path.
  ///
  /// Ensures:
  /// - Imported modules are registered first.
  /// - `binds()` executes only once per module type.
  /// - Cyclic imports are ignored.
  /// - The route is registered only if `path != '/'`.
  ///
  /// [path]    The route path to register.
  /// [module]  Optional module instance to register instead of `this`.
  void _register({String? path, Module? module}) {
    final targetModule = module ?? this;

    if (_modulesRegistered.contains(targetModule.runtimeType)) return;

    for (final imported in targetModule.imports()) {
      _register(path: path, module: imported);
    }

    if (!_modulesRegistered.contains(targetModule.runtimeType)) {
      targetModule.binds();
      _modulesRegistered.add(targetModule.runtimeType);

      Logger.module(
        '${targetModule.runtimeType} binds registered automatically',
      );
    }

    if (path != null && path.isNotEmpty && targetModule.routes().isNotEmpty) {
      _manager.module = targetModule;
      _manager.registerRoute(path, targetModule);
    }
  }
}
