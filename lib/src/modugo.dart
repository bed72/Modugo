import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/events/event_channel.dart';

import 'package:modugo/src/models/route_change_event_model.dart';

/// Global key for the main [Navigator] used by Modugo.
/// This key is used to access the navigator state globally,
/// allowing for imperative navigation and other operations
/// without needing to pass the context
GlobalKey<NavigatorState> modugoNavigatorKey = GlobalKey<NavigatorState>();

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
final class Modugo {
  static bool? _debugLogDiagnostics;
  static TypeTransition? _transition;

  /// Private constructor — this class is not meant to be instantiated.
  Modugo._();

  /// Internal singleton instance of [GoRouter].
  static GoRouter? _router;

  /// Shortcut to access the global GetIt instance used for dependency injection.
  /// Provides direct access to registered services and singletons.
  static GetIt get i => GetIt.instance;

  /// The default page transition to apply for all routes,
  /// unless explicitly overridden.
  static TypeTransition get getDefaultTransition =>
      _transition ?? TypeTransition.fade;

  /// Whether diagnostic logging is enabled for Modugo internals.
  ///
  /// Controlled by the `debugLogDiagnostics` flag passed to [configure].
  static bool get debugLogDiagnostics => _debugLogDiagnostics ?? false;

  /// Returns the configured [GoRouter] instance.
  ///
  /// Throws an [AssertionError] if [configure] was never called.
  static GoRouter get routerConfig {
    assert(_router != null, 'Add ModugoConfiguration.configure in main.dart');
    return _router!;
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

    final routes = module.configureRoutes();

    if (navigatorKey != null) modugoNavigatorKey = navigatorKey;

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
      navigatorKey: modugoNavigatorKey,
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

      EventChannel.emit(RouteChangedEventModel(current));
    });

    return _router!;
  }
}
