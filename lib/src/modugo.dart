import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:modugo/src/injector.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/transition.dart';

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

  static bool? _debugLogDiagnostics;
  static TypeTransition? _transition;

  /// Returns a dependency of type [T] from the [Injector].
  ///
  /// Shortcut for `Injector().get<T>()`.
  static T get<T>() => Injector().get<T>();

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
    int delayDisposeMilliseconds = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
    bool debugLogDiagnosticsGoRouter = false,
    bool overridePlatformDefaultLocation = false,
    TypeTransition pageTransition = TypeTransition.fade,
    Widget Function(BuildContext, GoRouterState)? errorBuilder,
    void Function(BuildContext, GoRouterState, GoRouter)? onException,
    FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
    Page<dynamic> Function(BuildContext, GoRouterState)? errorPageBuilder,
  }) async {
    if (_router != null) return _router!;

    _transition = pageTransition;
    _debugLogDiagnostics = debugLogDiagnostics;
    GoRouter.optionURLReflectsImperativeAPIs = true;

    final routes = module.configureRoutes(topLevel: true);
    setDisposeMiliseconds(delayDisposeMilliseconds);

    _router = GoRouter(
      routes: routes,
      redirect: redirect,
      observers: observers,
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
      refreshListenable: refreshListenable,
      restorationScopeId: restorationScopeId,
      debugLogDiagnostics: debugLogDiagnosticsGoRouter,
      overridePlatformDefaultLocation: overridePlatformDefaultLocation,
    );

    return _router!;
  }
}
