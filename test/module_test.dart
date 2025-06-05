import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';

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
}
