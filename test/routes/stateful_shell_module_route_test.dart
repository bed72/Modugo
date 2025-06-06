import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/modugo_mock.dart';
import '../mocks/modules_mock.dart';
import '../mocks/services_mock.dart';

void main() {
  final route = StatefulShellModuleRoute(
    routes: [],
    builder: (_, __, ___) => Container(),
  );

  test('base "/" + sub "/" → "/"', () {
    expect(route.composePath('/', '/'), '/');
  });

  test('base "/" + sub "home" → "/home"', () {
    expect(route.composePath('/', 'home'), '/home');
  });

  test('base "" + sub "home" → "/home"', () {
    expect(route.composePath('', 'home'), '/home');
  });

  test('base "/app/" + sub "/settings/" → "/app/settings"', () {
    expect(route.composePath('/app/', '/settings/'), '/app/settings');
  });

  test('base "/" + sub "" → "/"', () {
    expect(route.composePath('/', ''), '/');
  });

  test('base "/app" + sub "/" → "/app"', () {
    expect(route.composePath('/app', '/'), '/app');
  });

  test('normalizePath retorna "/" quando vazio', () {
    expect(route.normalizePath(''), '/');
  });

  test('normalizePath retorna o path original quando não está vazio', () {
    expect(route.normalizePath('/settings'), '/settings');
  });

  test('base "/" + sub "/" → "/" (normaliza múltiplas barras)', () {
    expect(route.composePath('/', '/'), '/');
  });

  test('base "//" + sub "//" → "/"', () {
    expect(route.composePath('//', '//'), '/');
  });

  test('base "///user" + sub "///details///" → "/user/details"', () {
    expect(route.composePath('///user', '///details///'), '/user/details');
  });

  test('base "" + sub "" → "/"', () {
    expect(route.composePath('', ''), '/');
  });

  test('base "home" + sub "" → "/home"', () {
    expect(route.composePath('home', ''), '/home');
  });

  test('base "" + sub "dashboard/" → "/dashboard"', () {
    expect(route.composePath('', 'dashboard/'), '/dashboard');
  });

  test('base "///" + sub "profile///settings" → "/profile/settings"', () {
    expect(route.composePath('///', 'profile///settings'), '/profile/settings');
  });

  test('should create StatefulShellRoute with ChildRoute', () {
    final route = StatefulShellModuleRoute(
      routes: [
        ChildRoute(
          '/',
          name: 'home',
          child: (context, state) => const Placeholder(),
        ),
      ],
      builder: (context, state, shell) => Scaffold(body: shell),
    );

    final result = route.toRoute(topLevel: true, path: '');

    expect(result, isA<StatefulShellRoute>());
  });

  test('should create StatefulShellRoute with ModuleRoute', () async {
    final module = OtherInnerModuleMock();
    await startModugoMock(module: module);

    final route = StatefulShellModuleRoute(
      routes: [ModuleRoute('/', module: module)],
      builder: (context, state, shell) => Scaffold(body: shell),
    );

    final result = route.toRoute(topLevel: true, path: '');

    expect(result, isA<StatefulShellRoute>());
  });

  test('should throw UnsupportedError for unknown route type', () {
    final route = StatefulShellModuleRoute(
      routes: [ModuleInterfaceMock()],
      builder: (context, state, shell) => Scaffold(body: shell),
    );

    expect(
      () => route.toRoute(topLevel: true, path: ''),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('should compose path correctly with nested ModuleRoute', () async {
    final module = OtherInnerModuleMock();
    await startModugoMock(module: module);

    final route = StatefulShellModuleRoute(
      routes: [ModuleRoute('/settings', module: module)],
      builder: (context, state, shell) => shell,
    );

    final result = route.toRoute(topLevel: true, path: '/app');
    expect(result, isA<StatefulShellRoute>());
  });
}
