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
      builder: (context, state, child) => Container(child: child),
      redirect: (context, state) async => null,
      observers: [NavigatorObserver()],
      pageBuilder:
          (context, state, child) =>
              MaterialPage(child: child, key: ValueKey('page')),
      navigatorKey: GlobalKey<NavigatorState>(),
      parentNavigatorKey: GlobalKey<NavigatorState>(),
      restorationScopeId: 'scope-1',
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
      builder: (_, __, ___) => const SizedBox(),
      redirect: (_, __) async => '/next',
    );

    final result = await route.redirect!(BuildContextFake(), StateFake());
    expect(result, equals('/next'));
  });

  test('should store binds when provided', () {
    final route = ShellModuleRoute(
      binds: [Bind.singleton((_) => 'hello')],
      routes: routes,
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
}
