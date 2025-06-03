import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:modugo/src/injectors/sync_injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/transitions/transition.dart';

typedef Modugo = ModugoConfiguration;

class ModugoConfiguration {
  ModugoConfiguration._();

  static GoRouter get routerConfig {
    assert(_router != null, 'Add ModugoConfiguration.configure in main.dart');
    return _router!;
  }

  static bool get debugLogDiagnostics {
    assert(
      _debugLogDiagnostics != null,
      'Add ModugoConfiguration.configure in main.dart',
    );
    return _debugLogDiagnostics!;
  }

  static TypeTransition get getDefaultPageTransition {
    assert(
      _transition != null,
      'Add ModugoConfiguration.configure in main.dart',
    );
    return _transition!;
  }

  static GoRouter? _router;

  static final manager = Manager();

  static bool? _debugLogDiagnostics;

  static TypeTransition? _transition;

  static T getSync<T>() => SyncBind.get<T>();

  static Future<T> getAsync<T>() => AsyncBind.get<T>();

  static String getCurrentPathOf(BuildContext context) =>
      GoRouterState.of(context).path ?? '';

  static GoRouterState stateOf(BuildContext context) =>
      GoRouterState.of(context);

  static Future<FutureOr<GoRouter>> configure({
    required Module module,
    Object? initialExtra,
    int redirectLimit = 5,
    bool requestFocus = true,
    String initialRoute = '/',
    String? restorationScopeId,
    bool routerNeglect = false,
    Listenable? refreshListenable,
    bool debugLogDiagnostics = true,
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

    final routes = await module.configureRoutes(topLevel: true);

    assert(
      delayDisposeMilliseconds > 500,
      '❌ delayDisposeMilliseconds must be at least 500ms - Check `go_router_modular main.dart`.',
    );
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
    debugLogDiagnostics = debugLogDiagnostics;
    return _router!;
  }
}
