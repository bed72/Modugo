import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import 'fakes/fakes.dart';
import 'mocks/modugo_mock.dart';
import 'mocks/modules_mock.dart';
import 'mocks/services_mock.dart';

void main() {
  setUp(() async {
    Bind.clearAll();

    final manager = Manager();
    manager.module = null;
    manager.bindsToDispose.clear();
    manager.bindReferences.clear();
  });

  test('Imported modules register their binds', () async {
    final module = MultiModulesInnerModuleMock();
    await startModugoMock(module: module);

    final imported = Bind.get<ModulesRepositoryMock>();

    expect(imported, isA<ModulesRepositoryMock>());
  });

  test('Module.configureRoutes creates valid RouteBase list', () async {
    final module = OtherModuleMock();
    await startModugoMock(module: module, debugLogDiagnostics: true);
    final routes = module.configureRoutes(topLevel: true);

    expect(routes, isA<List<RouteBase>>());
    expect(routes.length, 3);

    final child = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/home',
    );
    expect(child, isNotNull);

    final moduleRoute = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/profile',
    );
    expect(moduleRoute.routes.length, 1);

    final shell = routes.whereType<ShellRoute>().first;
    expect(shell, isNotNull);

    final syncService = Bind.get<ServiceMock>();

    expect(syncService, isNotNull);
    expect(syncService, isA<ServiceMock>());
  });

  test('ModuleRoute uses "/" ChildRoute as default', () async {
    final module = RootModuleMock();
    await startModugoMock(module: module);

    final routes = module.configureRoutes(topLevel: true);
    final profileRoute = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/profile',
    );

    expect(profileRoute.name, equals('profile-root'));
  });

  test('ChildRoute with "/" is excluded from _createChildRoutes', () async {
    final module = RootModuleMock();
    await startModugoMock(module: module);

    final routes = module.configureRoutes(topLevel: true);
    final paths = routes.whereType<GoRoute>().map((r) => r.path);

    expect(paths.contains('/'), isFalse);
  });

  test('ModuleRoute redirect is passed to GoRoute', () async {
    final module = ModuleWithRedirectMock();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    final redirected = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/',
    );

    final redirectResult = redirected.redirect?.call(
      BuildContextFake(),
      StateFake(),
    );

    expect(redirectResult, equals('/home'));
  });

  test('should register binds before building transition child', () async {
    final module = InnerModuleMock();
    await startModugoMock(module: module);
    module.configureRoutes(topLevel: true);

    ChildRoute(
      'home',
      child: (_, __) {
        final service = Bind.get<ServiceMock>();

        expect(service, isA<CustomTransitionPage>());
        return const Placeholder();
      },
    );
  });

  test('should register binds before calling child in GoRoute', () async {
    final module = RootModuleMock();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    final goRoute = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/profile',
    );

    final widget = goRoute.builder!(BuildContextFake(), StateFake());

    expect(widget, isA<Placeholder>());
  });

  test('should create ShellRoute and register shell binds', () async {
    final module = ModuleWithShellMock();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    final shell = routes.whereType<ShellRoute>().first;

    expect(shell, isA<ShellRoute>());

    final controller = Bind.get<ServiceMock>();
    expect(controller, isA<ServiceMock>());
  });

  test('includes "/" when topLevel is true', () async {
    final module = ModuleWithRoot();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    expect(routes.whereType<GoRoute>().any((r) => r.path == '/'), isTrue);
  });

  test('excludes "/" when topLevel is false', () async {
    final module = ModuleWithRoot();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: false);

    expect(routes.whereType<GoRoute>().any((r) => r.path == '/'), isFalse);
  });

  test('includes "" as "/" when topLevel is true', () async {
    final module = ModuleWithEmpty();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    expect(routes.whereType<GoRoute>().any((r) => r.path == '/'), isTrue);
  });

  test('should include StatefulShellRoute when declared in routes', () async {
    final module = ModuleWithStatefulShellMock();
    await startModugoMock(module: module);
    final routes = module.configureRoutes(topLevel: true);

    expect(routes.whereType<StatefulShellRoute>().length, 1);
  });

  test(
    'should build branches from ModuleRoute inside StatefulShellModuleRoute',
    () async {
      final module = ModuleWithStatefulShellMock();
      await startModugoMock(module: module);

      final routes = module.configureRoutes(topLevel: true);
      final shellRoute = routes.whereType<StatefulShellRoute>().first;

      final branches = shellRoute.branches;
      expect(branches.length, equals(2));

      for (final branch in branches) {
        final goRoutes = branch.routes.whereType<GoRoute>();
        expect(goRoutes.isNotEmpty, isTrue);
      }
    },
  );

  test(
    'should throw UnsupportedError if unknown route type in StatefulShellModuleRoute',
    () {
      expect(() {
        StatefulShellModuleRoute(
          builder: (ctx, state, shell) => const Placeholder(),
          routes: [ModuleInterfaceMock()],
        ).toRoute(topLevel: true, path: '');
      }, throwsA(isA<UnsupportedError>()));
    },
  );
}
