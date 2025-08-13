import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/notifiers/router_notifier.dart';
import 'package:modugo/src/models/route_pattern_model.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/match_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Alias for the core configuration class used to bootstrap and manage Modugo.
///
/// This allows writing `Modugo.configure(...)` instead of the full class name.
typedef Modugo = ModugoConfiguration;

/// Global key for the main [Navigator] used by Modugo.
/// This key is used to access the navigator state globally,
/// allowing for imperative navigation and other operations
/// without needing to pass the context
late GlobalKey<NavigatorState> modularNavigatorKey;

/// The central configuration class for the Modugo routing and dependency system.
///
/// This class is responsible for:
/// - initializing the [GoRouter] instance
/// - holding global settings like [TypeTransition] and diagnostic logging
/// - exposing access to dependency injection via [get<T>()]
///
/// It should be initialized once at the root of the app using [configure],
/// typically inside `main()` before running the app.
///
/// Example:
/// ```dart
/// void main() async {
///   await Modugo.configure(module: AppModule());
///   runApp(MyApp());
/// }
/// ```
final class ModugoConfiguration {
  /// Private constructor — this class is not meant to be instantiated.
  ModugoConfiguration._();

  /// Returns the configured [GoRouter] instance.
  ///
  /// Throws an [AssertionError] if [configure] was never called.
  static GoRouter get routerConfig {
    assert(_router != null, 'Add ModugoConfiguration.configure in main.dart');
    return _router!;
  }

  /// Whether diagnostic logging is enabled for Modugo internals.
  ///
  /// Controlled by the `debugLogDiagnostics` flag passed to [configure].
  static bool get debugLogDiagnostics => _debugLogDiagnostics ?? false;

  /// The default page transition to apply for all routes,
  /// unless explicitly overridden.
  static TypeTransition get getDefaultTransition =>
      _transition ?? TypeTransition.fade;

  /// Internal singleton instance of [GoRouter].
  static GoRouter? _router;

  /// Global manager instance for handling modules and route lifecycle.
  static final manager = Manager();

  /// A global [RouteNotifier] that emits the current location path when navigation occurs.
  ///
  /// This is used internally by Modugo as the default [refreshListenable]
  /// for [GoRouter] if none is provided. It allows widgets or services
  /// to listen and react to navigation changes without directly depending on
  /// the router.
  ///
  /// Example:
  /// ```dart
  /// Modugo.routeNotifier.addListener(() {
  ///   final path = Modugo.routeNotifier.value;
  ///   if (path == '/home') {
  ///     refreshHomeCarousel();
  ///   }
  /// });
  /// ```
  static final routeNotifier = RouteNotifier();

  static bool? _debugLogDiagnostics;
  static TypeTransition? _transition;

  /// Returns a dependency of type [T] from the [Injector].
  ///
  /// Shortcut for `Injector().get<T>()`.
  static T get<T extends Object>({Type? type, String? instanceName}) =>
      GetIt.I.get<T>(type: type, instanceName: instanceName);

  /// Attempts to match a given [location] to a registered route with a [RoutePatternModel].
  ///
  /// Returns a [MatchRoute] containing the matched route and extracted parameters,
  /// or `null` if no match is found.
  static MatchRoute? matchRoute(String location) {
    final allModules = _collectModules(Modugo.manager.rootModule);

    for (final module in allModules) {
      for (final route in module.routes()) {
        final match = _matchRouteRecursive(route, location);
        if (match != null) return match;
      }
    }

    return null;
  }

  /// Configures the entire Modugo system by:
  /// - building the root router from the [module]
  /// - injecting global options such as transitions, logging, and error handlers
  /// - returning a ready-to-use [GoRouter] instance
  ///
  /// Must be called before any navigation occurs.
  ///
  /// Parameters:
  /// - [module]: the root module containing all binds and routes
  /// - [pageTransition]: default page transition for all routes
  /// - [debugLogDiagnostics]: enables internal logging for debugging
  /// - [delayDisposeMilliseconds]: time to keep inactive modules alive
  /// - [observers], [navigatorKey], [redirect], [errorBuilder], etc: standard GoRouter options
  ///
  /// Returns the initialized [GoRouter].
  static FutureOr<GoRouter> configure({
    required Module module,
    Object? initialExtra,
    int redirectLimit = 5,
    bool requestFocus = true,
    String initialRoute = '/',
    String? restorationScopeId,
    bool routerNeglect = false,
    Listenable? refreshListenable,
    bool debugLogDiagnostics = false,
    List<NavigatorObserver>? observers,
    Codec<Object?, Object?>? extraCodec,
    GlobalKey<NavigatorState>? navigatorKey,
    bool debugLogDiagnosticsGoRouter = false,
    bool overridePlatformDefaultLocation = false,
    TypeTransition pageTransition = TypeTransition.fade,
    Widget Function(BuildContext, GoRouterState)? errorBuilder,
    void Function(BuildContext, GoRouterState, GoRouter)? onException,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    Page<dynamic> Function(BuildContext, GoRouterState)? errorPageBuilder,
  }) {
    if (_router != null) return _router!;

    _transition = pageTransition;
    _debugLogDiagnostics = debugLogDiagnostics;
    GoRouter.optionURLReflectsImperativeAPIs = true;

    final routes = module.configureRoutes(topLevel: true);

    modularNavigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

    _router = GoRouter(
      routes: routes,
      redirect: redirect,
      observers: observers,
      extraCodec: extraCodec,
      onException: onException,
      errorBuilder: errorBuilder,
      initialExtra: initialExtra,
      requestFocus: requestFocus,
      redirectLimit: redirectLimit,
      routerNeglect: routerNeglect,
      initialLocation: initialRoute,
      navigatorKey: modularNavigatorKey,
      errorPageBuilder: errorPageBuilder,
      refreshListenable: refreshListenable,
      restorationScopeId: restorationScopeId,
      debugLogDiagnostics: debugLogDiagnosticsGoRouter,
      overridePlatformDefaultLocation: overridePlatformDefaultLocation,
    );

    String? lastNotifiedLocation;

    _router?.routerDelegate.addListener(() {
      final config = _router?.routerDelegate.currentConfiguration;

      if (config == null || config.isEmpty) return;

      final current = config.last.matchedLocation;

      if (current.isEmpty) return;
      if (current == lastNotifiedLocation) return;

      lastNotifiedLocation = current;

      Logger.warn('UPDATE NOTIFIER BY ROUTE $current');
      routeNotifier.update = current;
    });

    return _router!;
  }

  /// Recursively attempts to match a single [IModule] route (any type) to the [location].
  static MatchRoute? _matchRouteRecursive(IModule route, String location) {
    final pattern = switch (route) {
      ChildRoute r => r.routePattern,
      ModuleRoute r => r.routePattern,
      ShellModuleRoute r => r.routePattern,
      StatefulShellModuleRoute r => r.routePattern,
      _ => null,
    };

    if (pattern != null && pattern.regex.hasMatch(location)) {
      final params = pattern.extractParams(location);
      return MatchRoute(route: route, params: params);
    }

    final childRoutes = switch (route) {
      ModuleRoute r => r.module.routes(),
      ShellModuleRoute r => r.routes,
      StatefulShellModuleRoute r => r.routes,
      _ => null,
    };

    if (childRoutes != null) {
      for (final child in childRoutes) {
        final match = _matchRouteRecursive(child, location);
        if (match != null) return match;
      }
    }

    return null;
  }

  /// Recursively flattens all modules starting from [root].
  static List<Module> _collectModules(Module root) {
    final buffer = <Module>[];

    void visit(Module module) {
      buffer.add(module);
      for (final imported in module.imports()) {
        visit(imported);
      }
    }

    visit(root);
    return buffer;
  }
}
