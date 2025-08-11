import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';

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
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: routes,
        navigatorKey: key,
        observers: observers,
        parentNavigatorKey: key,
        restorationScopeId: 'scope',
        builder: (_, _, _) => const Placeholder(),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal when routes differ', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute(), _DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when observer lists differ', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        observers: [NavigatorObserver()],
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        observers: [NavigatorObserver()],
        builder: (_, _, _) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('creates ShellModuleRoute with binds, keys and layout', () {
      final shellKey = GlobalKey<NavigatorState>();
      final parentKey = GlobalKey<NavigatorState>();

      final route = ShellModuleRoute(
        binds: [(_) {}],
        navigatorKey: shellKey,
        restorationScopeId: 'shell',
        parentNavigatorKey: parentKey,
        builder: (_, _, child) => Material(child: child),
        routes: [ModuleRoute(path: '/', module: _DummyModule())],
      );

      expect(route.routes, hasLength(1));
      expect(route.navigatorKey, shellKey);
      expect(route.restorationScopeId, 'shell');
      expect(route.parentNavigatorKey, parentKey);
    });

    test('should not be equal when navigatorKey differs', () {
      final a = ShellModuleRoute(
        navigatorKey: GlobalKey(),
        routes: [_DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        navigatorKey: GlobalKey(),
        routes: [_DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when restorationScopeId differs', () {
      final a = ShellModuleRoute(
        restorationScopeId: 'scope1',
        routes: [_DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        restorationScopeId: 'scope2',
        routes: [_DummyModuleRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when parentNavigatorKey differs', () {
      final a = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        parentNavigatorKey: GlobalKey(),
        builder: (_, _, _) => const Placeholder(),
      );

      final b = ShellModuleRoute(
        routes: [_DummyModuleRoute()],
        parentNavigatorKey: GlobalKey(),
        builder: (_, _, _) => const Placeholder(),
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
        redirect: (_, _) async => '/redirect',
        builder: (_, _, _) => const Placeholder(),
        binds: [(i) => i.addFactory<int>((_) => 123)],
        pageBuilder: (_, _, child) => MaterialPage(child: child),
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
        builder: (_, _, _) => const Placeholder(),
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
      builder: (_, _, _) => const Placeholder(),
      binds: [(i) => i.addSingleton<String>((_) => 'test-string')],
    );

    route.binds.first(Injector());

    final result = Injector().get<String>();
    expect(result, equals('test-string'));
  });

  test('should register multiple binds with distinct types', () {
    final route = ShellModuleRoute(
      routes: [_DummyModuleRoute()],
      builder: (_, _, _) => const Placeholder(),
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
      builder: (_, _, _) => const Placeholder(),
    );

    final altered = ShellModuleRoute(
      routes: [dummyRoute],
      builder: (_, _, _) => const Placeholder(),
      binds: [(i) => i.addFactory((_) => 'irrelevant')],
    );

    expect(base, equals(altered));
  });

  group('ShellModuleRoute with RoutePatternModel', () {
    test('matches correct path and extracts parameters', () {
      final route = ShellModuleRoute(
        builder: (_, _, _) => const Placeholder(),
        routes: [ModuleRoute(path: '/home', module: _DummyModule())],
        routePattern: RoutePatternModel.from(
          r'^/org/(\w+)/home$',
          paramNames: ['orgId'],
        ),
      );

      final pattern = route.routePattern!;
      expect(pattern.regex.hasMatch('/org/acme/home'), isTrue);

      final params = pattern.extractParams('/org/acme/home');
      expect(params, equals({'orgId': 'acme'}));
    });

    test('returns false when path does not match pattern', () {
      final route = ShellModuleRoute(
        routes: [],
        builder: (_, _, _) => const Placeholder(),
        routePattern: RoutePatternModel.from(
          r'^/dashboard/(\w+)$',
          paramNames: ['section'],
        ),
      );

      final match = route.routePattern!.regex.hasMatch('/settings/profile');
      expect(match, isFalse);

      final params = route.routePattern!.extractParams('/settings/profile');
      expect(params, isEmpty);
    });

    test('== returns true when all fields including routePattern match', () {
      final pattern = RoutePatternModel.from(r'^/shell$', paramNames: []);
      final routeA = ShellModuleRoute(
        routes: [],
        builder: (_, _, _) => const Placeholder(),
        routePattern: pattern,
      );
      final routeB = ShellModuleRoute(
        routes: [],
        builder: (_, _, _) => const Placeholder(),
        routePattern: pattern,
      );

      expect(routeA, equals(routeB));
      expect(routeA.hashCode, equals(routeB.hashCode));
    });

    test('== returns false when routePatterns differ', () {
      final routeA = ShellModuleRoute(
        routes: [],
        builder: (_, _, _) => const Placeholder(),
        routePattern: RoutePatternModel.from(r'^/a$', paramNames: []),
      );
      final routeB = ShellModuleRoute(
        routes: [],
        builder: (_, _, _) => const Placeholder(),
        routePattern: RoutePatternModel.from(r'^/b$', paramNames: []),
      );

      expect(routeA, isNot(equals(routeB)));
    });
  });
}

final class _DummyModuleRoute implements IModule {}

final class _DummyModule extends Module {
  @override
  List<IModule> routes() => [];
}
