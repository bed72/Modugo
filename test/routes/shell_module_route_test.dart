import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

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
        binds: [(i) => i.registerFactory<int>(() => 123)],
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

  test('should register multiple binds with distinct types', () {
    final route = ShellModuleRoute(
      routes: [_DummyModuleRoute()],
      builder: (_, _, _) => const Placeholder(),
      binds: [
        (i) => i.registerFactory<int>(() => 42),
        (i) => i.registerSingleton<String>('value'),
      ],
    );

    for (final bind in route.binds) {
      bind(GetIt.I);
    }

    expect(GetIt.I.get<int>(), equals(42));
    expect(GetIt.I.get<String>(), equals('value'));
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
      binds: [(i) => i.registerFactory(() => 'irrelevant')],
    );

    expect(base, equals(altered));
  });
}

final class _DummyModuleRoute implements IRoute {}

final class _DummyModule extends Module {
  @override
  List<IRoute> routes() => [];
}
