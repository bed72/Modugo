import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

void main() {
  group('ShellModuleRoute - equality and hashCode', () {
    test('should be equal when all relevant fields are equal', () {
      final routes = [_DummyModuleRoute()];
      final observers = <NavigatorObserver>[];
      final key = GlobalKey<NavigatorState>();

      final a = ShellModuleRoute(
        routes: routes,
        navigatorKey: key,
        observers: observers,
        parentNavigatorKey: key,
        restorationScopeId: 'scope',
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: routes,
        navigatorKey: key,
        observers: observers,
        parentNavigatorKey: key,
        restorationScopeId: 'scope',
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal when routes differ', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute(), _DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when observer lists differ', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        observers: [NavigatorObserver()],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        observers: [NavigatorObserver()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when navigatorKey differs', () {
      final a = ShellModuleRoute(
        navigatorKey: GlobalKey(),
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        navigatorKey: GlobalKey(),
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when restorationScopeId differs', () {
      final a = ShellModuleRoute(
        restorationScopeId: 'scope1',
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        restorationScopeId: 'scope2',
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when parentNavigatorKey differs', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        parentNavigatorKey: GlobalKey(),
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        parentNavigatorKey: GlobalKey(),
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('ShellModuleRoute - field assignment', () {
    test('should assign required and optional fields correctly', () {
      final observer = NavigatorObserver();
      final parentKey = GlobalKey<NavigatorState>();
      final navigatorKey = GlobalKey<NavigatorState>();

      final route = ShellModuleRoute(
        observers: [observer],
        navigatorKey: navigatorKey,
        parentNavigatorKey: parentKey,
        routes: [_DummyModuleRoute()],
        restorationScopeId: 'restore-1',
        redirect: (_, __) async => '/redirect',
        builder: (_, __, ___) => const Placeholder(),
        binds: [(i) => i.addFactory<int>((_) => 123)],
        pageBuilder: (_, __, child) => MaterialPage(child: child),
      );

      expect(route.binds.length, 1);
      expect(route.routes.length, 1);
      expect(route.redirect, isNotNull);
      expect(route.observers?.length, 1);
      expect(route.pageBuilder, isNotNull);
      expect(route.navigatorKey, navigatorKey);
      expect(route.parentNavigatorKey, parentKey);
      expect(route.restorationScopeId, 'restore-1');
    });

    test('should handle minimal constructor input', () {
      final route = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(route.binds, isEmpty);
      expect(route.observers, isNull);
      expect(route.redirect, isNull);
      expect(route.pageBuilder, isNull);
      expect(route.navigatorKey, isNull);
      expect(route.parentNavigatorKey, isNull);
      expect(route.restorationScopeId, isNull);
    });
  });

  test('should execute bind and register in Injector', () {
    final route = ShellModuleRoute(
      routes: [_DummyModuleRoute()],
      builder: (_, __, ___) => const Placeholder(),
      binds: [(i) => i.addSingleton<String>((_) => 'test-string')],
    );

    route.binds.first(Injector());

    final result = Injector().get<String>();
    expect(result, equals('test-string'));
  });

  test('should register multiple binds with distinct types', () {
    final route = ShellModuleRoute(
      routes: [_DummyModuleRoute()],
      builder: (_, __, ___) => const Placeholder(),
      binds: [
        (i) => i.addSingleton<String>((_) => 'value'),
        (i) => i.addFactory<int>((_) => 42),
      ],
    );

    for (final bind in route.binds) {
      bind(Injector());
    }

    expect(Injector().get<String>(), equals('value'));
    expect(Injector().get<int>(), equals(42));
  });

  test('should consider routes equal even if binds differ', () {
    final dummyRoute = _DummyModuleRoute();

    final base = ShellModuleRoute(
      routes: [dummyRoute],
      builder: (_, __, ___) => const Placeholder(),
    );

    final altered = ShellModuleRoute(
      routes: [dummyRoute],
      builder: (_, __, ___) => const Placeholder(),
      binds: [(i) => i.addFactory((_) => 'irrelevant')],
    );

    expect(base, equals(altered));
  });

  group('ShellModuleRoute - guards', () {
    test('should assign guards correctly', () {
      final guardA = _FakeGuardAllow();
      final guardB = _FakeGuardBlock('/forbidden');

      final route = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
        guards: [guardA, guardB],
      );

      expect(route.guards.length, 2);
      expect(route.guards.first, guardA);
      expect(route.guards.last, guardB);
    });

    test('should default to empty guards list when not provided', () {
      final route = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(route.guards, isEmpty);
    });

    test('should allow equality even if guards differ', () {
      final dummy = _DummyModuleRoute();

      final base = ShellModuleRoute(
        routes: [dummy],
        builder: (_, __, ___) => const Placeholder(),
        guards: [_FakeGuardAllow()],
      );

      final other = ShellModuleRoute(
        routes: [dummy],
        builder: (_, __, ___) => const Placeholder(),
        guards: [_FakeGuardBlock('/denied')],
      );

      expect(base, equals(other));
    });

    test('ShellModuleRoute should redirect if any guard blocks', () async {
      final shellRoute = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, __, ___) => const Placeholder(),
        guards: [_BlockingGuard()],
      );

      final redirectFn =
          (ShellRoute(
            routes: [
              GoRoute(
                path: '/placeholder',
                builder: (_, __) => const Placeholder(),
              ),
            ],
            builder: (context, state, child) => const Placeholder(),
            redirect: (context, state) async {
              for (final guard in shellRoute.guards) {
                final result = await guard.call(context, state);
                if (result != null) return result;
              }

              if (shellRoute.redirect != null) {
                return await shellRoute.redirect!(context, state);
              }

              return null;
            },
          ).redirect)!;

      final result = await redirectFn(_FakeContext(), _FakeState());

      expect(result, '/blocked');
    });

    test(
      'ShellModuleRoute redirect is triggered via guard when building real routes',
      () async {
        final module = _ShellGuardedModule();

        final routes = module.configureRoutes(topLevel: true);

        final shellRoute = routes.whereType<ShellRoute>().first;

        final redirectFn = shellRoute.redirect!;
        final result = await redirectFn(_FakeContext(), _FakeState());

        expect(result, '/blocked');
      },
    );
  });
}

final class _DummyModuleRoute implements IModule {}

final class _ShellGuardedModule extends Module {
  @override
  List<IModule> get routes => [
    ShellModuleRoute(
      guards: [_BlockingGuard()],
      builder: (_, __, child) => child,
      routes: [ChildRoute('/inside', child: (_, __) => const Placeholder())],
    ),
  ];
}

final class _BlockingGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}

final class _FakeGuardAllow implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}

final class _FakeGuardBlock implements IGuard {
  final String redirectPath;
  _FakeGuardBlock(this.redirectPath);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      redirectPath;
}

final class _FakeContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeState extends GoRouterState {
  _FakeState()
    : super(
        RouteConfiguration(
          ValueNotifier(RoutingConfig(routes: [])),
          navigatorKey: GlobalKey<NavigatorState>(),
        ),
        fullPath: '/',
        uri: Uri.parse('/'),
        matchedLocation: '/',
        pathParameters: const {},
        pageKey: const ValueKey('fake'),
      );
}
