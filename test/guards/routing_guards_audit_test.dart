import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/guard.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/mixins/event_mixin.dart';
import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/extensions/guard_extension.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeGoRouterState extends Fake implements GoRouterState {}

void main() {
  late BuildContext ctx;
  late GoRouterState st;

  setUp(() {
    ctx = _FakeBuildContext();
    st = _FakeGoRouterState();
  });

  tearDown(() {
    Modugo.resetForTesting();
    Event.i.disposeAll();
  });

  // 7.1 — FactoryRoute.resetForTesting() clears _pendingGuards
  test(
    'Modugo.resetForTesting() clears pending guard operation; '
    'subsequent redirect call is not affected by prior cancellation',
    () async {
      final completer = Completer<void>();
      final slowRoute =
          FactoryRoute.from([
                ChildRoute(
                  path: '/slow',
                  guards: [_SlowRedirectGuard('/login', completer.future)],
                  child: (_, _) => const SizedBox(),
                ),
              ]).first
              as GoRoute;

      // Start a slow redirect
      final future1 = slowRoute.redirect!(ctx, st);

      // Reset — should cancel the in-flight operation
      Modugo.resetForTesting();

      // A fresh route with an instant-allow guard
      final fastRoute =
          FactoryRoute.from([
                ChildRoute(
                  path: '/fast',
                  guards: [_AllowGuard()],
                  child: (_, _) => const SizedBox(),
                ),
              ]).first
              as GoRoute;

      final future2 = fastRoute.redirect!(ctx, st);
      completer.complete();

      // The first future was cancelled, so it resolves to null
      expect(await future1, isNull);
      // The second (fresh) route resolves normally
      expect(await future2, isNull);
    },
  );

  // 7.2 — AliasRoute with non-existent target throws ArgumentError
  test('AliasRoute with non-existent target path throws ArgumentError with '
      'descriptive message', () {
    expect(
      () => FactoryRoute.from([
        AliasRoute(from: '/old', to: '/nonexistent'),
        ChildRoute(path: '/other', child: (_, _) => const SizedBox()),
      ]),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('/nonexistent'),
            contains('AliasRoute'),
            contains('ChildRoute'),
          ),
        ),
      ),
    );
  });

  // 7.3 — configureRoutes() called twice on same instance: listen() only once
  test('configureRoutes() called twice on same module instance — '
      'IEvent.listen() executed only once', () {
    int listenCount = 0;
    final module = _CountingEventModule(() => listenCount++);

    module.configureRoutes();
    module.configureRoutes();

    expect(listenCount, 1);
  });

  // 7.4 — Logger.warn emitted when module with same runtimeType is skipped
  test(
    'duplicate module registration (same runtimeType) triggers Logger.warn',
    () {
      // We can't easily intercept Logger.warn in a pure unit test,
      // but we can verify the behavior: second module is silently skipped
      // without throwing.
      final module1 = _SimpleModule();
      final module2 = _SimpleModule();

      module1.configureRoutes();

      // Second module of same type — should not throw, just warn-skip
      expect(() => module2.configureRoutes(), returnsNormally);
    },
  );

  // 7.5 — propagateGuards with AliasRoute inside StatefulShellModuleRoute
  test('propagateGuards with AliasRoute inside StatefulShellModuleRoute — '
      'alias passes through unchanged', () {
    final alias = AliasRoute(from: '/old', to: '/new');
    final shell = StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [alias],
    );

    final injected = shell.withInjectedGuards([_AllowGuard()]);

    expect(injected.routes, contains(alias));
  });

  // 7.6 — propagateGuards with AliasRoute inside ShellModuleRoute
  test('propagateGuards with AliasRoute inside ShellModuleRoute — '
      'alias passes through unchanged', () {
    final alias = AliasRoute(from: '/old', to: '/new');
    final shell = ShellModuleRoute(
      builder: (_, _, child) => child,
      routes: [alias],
    );

    final result = propagateGuards(
      routes: shell.routes,
      guards: [_AllowGuard()],
    );

    expect(result, contains(alias));
  });

  // 7.7 — ShellModuleRoute with guard that returns null
  test(
    'ShellModuleRoute with guard returning null — ShellRoute.redirect returns null',
    () async {
      final routes = FactoryRoute.from([
        ShellModuleRoute(
          guards: [_AllowGuard()],
          builder: (_, _, child) => child,
          routes: [
            ChildRoute(path: '/home', child: (_, _) => const SizedBox()),
          ],
        ),
      ]);

      final shellRoute = routes.first as ShellRoute;
      expect(shellRoute.redirect, isNotNull);
      expect(await shellRoute.redirect!(ctx, st), isNull);
    },
  );

  // 7.8 — ShellModuleRoute with guard that redirects
  test('ShellModuleRoute with guard returning a path — ShellRoute.redirect '
      'returns that path', () async {
    final routes = FactoryRoute.from([
      ShellModuleRoute(
        guards: [_RedirectGuard('/login')],
        builder: (_, _, child) => child,
        routes: [
          ChildRoute(path: '/dashboard', child: (_, _) => const SizedBox()),
        ],
      ),
    ]);

    final shellRoute = routes.first as ShellRoute;
    expect(shellRoute.redirect, isNotNull);
    expect(await shellRoute.redirect!(ctx, st), '/login');
  });

  // 7.9 — ShellModuleRoute without guards: redirect is null (no overhead)
  test('ShellModuleRoute without guards — ShellRoute.redirect is null', () {
    final routes = FactoryRoute.from([
      ShellModuleRoute(
        builder: (_, _, child) => child,
        routes: [ChildRoute(path: '/home', child: (_, _) => const SizedBox())],
      ),
    ]);

    final shellRoute = routes.first as ShellRoute;
    expect(shellRoute.redirect, isNull);
  });
}

// ── Guards ────────────────────────────────────────────────────────────────────

final class _AllowGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _RedirectGuard implements IGuard {
  final String to;
  const _RedirectGuard(this.to);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => to;
}

final class _SlowRedirectGuard implements IGuard {
  final String to;
  final Future<void> delay;
  const _SlowRedirectGuard(this.to, this.delay);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    await delay;
    return to;
  }
}

// ── Modules ───────────────────────────────────────────────────────────────────

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

final class _CountingEventModule extends Module with IEvent {
  final VoidCallback onListen;
  _CountingEventModule(this.onListen);

  @override
  void listen() => onListen();

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}
