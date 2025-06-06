import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/injector.dart';

import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import '../fakes/fakes.dart';
import '../mocks/route_mock.dart';

void main() {
  late ShellModuleRoute shellRoute;
  late List<ModuleInterface> routes;

  setUp(() {
    routes = [DummyModuleRouteMock()];
    shellRoute = ShellModuleRoute(
      routes: routes,
      restorationScopeId: 'scope-1',
      redirect: (context, state) async => null,
      navigatorKey: GlobalKey<NavigatorState>(),
      parentNavigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, state, child) => Container(child: child),
      observers: [NavigatorObserver()],
      pageBuilder:
          (context, state, child) =>
              MaterialPage(child: child, key: ValueKey('page')),
    );
  });

  test('should instantiate with all properties', () {
    expect(shellRoute.routes, routes);
    expect(shellRoute.builder, isNotNull);
    expect(shellRoute.redirect, isNotNull);
    expect(shellRoute.observers, isNotEmpty);
    expect(shellRoute.pageBuilder, isNotNull);
    expect(shellRoute.navigatorKey, isNotNull);
    expect(shellRoute.parentNavigatorKey, isNotNull);
    expect(shellRoute.restorationScopeId, 'scope-1');
  });

  test('equality works correctly', () {
    final sameShellRoute = ShellModuleRoute(
      routes: routes,
      builder: shellRoute.builder,
      redirect: shellRoute.redirect,
      observers: shellRoute.observers,
      pageBuilder: shellRoute.pageBuilder,
      navigatorKey: shellRoute.navigatorKey,
      parentNavigatorKey: shellRoute.parentNavigatorKey,
      restorationScopeId: shellRoute.restorationScopeId,
    );

    expect(shellRoute, equals(sameShellRoute));

    final differentShellRoute = ShellModuleRoute(
      routes: [],
      builder: shellRoute.builder,
    );

    expect(shellRoute == differentShellRoute, isFalse);
  });

  test('should execute redirect and return expected path', () async {
    final route = ShellModuleRoute(
      routes: routes,
      redirect: (_, __) async => '/next',
      builder: (_, __, ___) => const SizedBox(),
    );

    final result = await route.redirect!(BuildContextFake(), StateFake());

    expect(result, equals('/next'));
  });

  test('should store binds when provided', () {
    final route = ShellModuleRoute(
      routes: routes,
      binds: [Bind.singleton((_) => 'hello')],
      builder: (_, __, ___) => const SizedBox(),
    );

    expect(route.binds, isNotEmpty);
    expect(route.binds.first.factoryFunction(Injector()), equals('hello'));
  });

  test('binds do not affect equality', () {
    final route1 = ShellModuleRoute(
      routes: routes,
      binds: [Bind.singleton((_) => 1)],
      builder: (_, __, ___) => const SizedBox(),
    );

    final route2 = ShellModuleRoute(
      routes: routes,
      binds: [Bind.singleton((_) => 2)],
      builder: (_, __, ___) => const SizedBox(),
    );

    expect(route1, equals(route2));
  });

  test('builder builds widget with child', () {
    final route = ShellModuleRoute(
      routes: [],
      builder:
          (_, __, child) =>
              Container(key: const ValueKey('test'), child: child),
    );

    final widget = route.builder!(
      BuildContextFake(),
      StateFake(),
      const Text('Child'),
    );
    expect(widget is Container, isTrue);
    expect(widget.key, const ValueKey('test'));
  });
}
