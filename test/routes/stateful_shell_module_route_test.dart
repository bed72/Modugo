import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/modugo_mock.dart';
import '../mocks/modules_mock.dart';
import '../mocks/services_mock.dart';

void main() {
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

  group('composePath', () {
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
  });
}
