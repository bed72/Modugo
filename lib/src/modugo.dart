import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/observers/router_observer.dart';
import 'package:modugo/src/notifiers/router_notifier.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/match_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Alias for the core configuration class used to bootstrap and manage Modugo.
///
/// This allows writing `Modugo.configure(...)` instead of the full class name.
typedef Modugo = ModugoConfiguration;

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
  static T get<T>() => Injector().get<T>();

  /// Attempts to match a given [location] to a registered route with a [RoutePatternModel].
  ///
  /// Returns a [MatchRoute] containing the matched route and extracted parameters,
  /// or `null` if no match is found.
  static MatchRoute? matchRoute(String location) {
    final allModules = _collectModules(Modugo.manager.rootModule);

    for (final module in allModules) {
      for (final route in module.routes) {
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
    int delayDisposeMilliseconds = 727,
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
    setDisposeMiliseconds(delayDisposeMilliseconds);

    _router = GoRouter(
      routes: routes,
      redirect: redirect,
      extraCodec: extraCodec,
      onException: onException,
      errorBuilder: errorBuilder,
      initialExtra: initialExtra,
      requestFocus: requestFocus,
      navigatorKey: navigatorKey,
      redirectLimit: redirectLimit,
      routerNeglect: routerNeglect,
      initialLocation: initialRoute,
      errorPageBuilder: errorPageBuilder,
      restorationScopeId: restorationScopeId,
      debugLogDiagnostics: debugLogDiagnosticsGoRouter,
      observers: [RouteTrackingObserver(), ...?observers],
      refreshListenable: refreshListenable ?? routeNotifier,
      overridePlatformDefaultLocation: overridePlatformDefaultLocation,
    );

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

    if (route is ModuleRoute) {
      final childRoutes = route.module.routes;
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
    void visit(Module mod) {
      buffer.add(mod);
      for (final imported in mod.imports) {
        visit(imported);
      }
    }

    visit(root);
    return buffer;
  }
}
