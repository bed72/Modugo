import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injectors/sync_injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/services_mock.dart';
import 'mocks/modules/modules_mock.dart';
import 'mocks/modules/async_modules_mock.dart';

void main() {
  setUp(() async {
    SyncBind.clearAll();
    await AsyncBind.clearAll();

    final manager = Manager();
    manager.module = null;
    manager.bindsToDispose.clear();
    manager.bindReferences.clear();
  });

  test('Module.registerBindsIfNeeded handles imported modules', () async {
    final module = ModuleWithSyncAndAsyncMock();
    await startModugoMock(module: module, debugLogDiagnostics: true);
    final routes = await module.configureRoutes(topLevel: true);

    final child = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/home',
    );
    expect(child, isNotNull);

    final asyncService = await AsyncBind.get<AsyncServiceMock>();
    expect(asyncService, isNotNull);
    expect(asyncService, isA<AsyncServiceMock>());

    final syncService = SyncBind.get<SyncServiceMock>();
    expect(syncService, isNotNull);
    expect(syncService, isA<SyncServiceMock>());
  });

  test('Module.configureRoutes registers async binds', () async {
    final module = ModuleWithAsyncMock();
    await startModugoMock(module: module, debugLogDiagnostics: true);
    final routes = await module.configureRoutes(topLevel: true);

    expect(routes, isA<List<RouteBase>>());
    expect(routes.length, 1);

    final child = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/home',
    );
    expect(child, isNotNull);

    final asyncService = await AsyncBind.get<AsyncServiceMock>();

    expect(asyncService, isNotNull);
    expect(asyncService, isA<AsyncServiceMock>());
  });

  test('Module.configureRoutes creates valid RouteBase list', () async {
    final module = OtherModuleMock();
    await startModugoMock(module: module, debugLogDiagnostics: true);
    final routes = await module.configureRoutes(topLevel: true);

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

    final syncService = SyncBind.get<SyncServiceMock>();

    expect(syncService, isNotNull);
    expect(syncService, isA<SyncServiceMock>());
  });

  test('ModuleRoute uses "/" ChildRoute as default', () async {
    final module = RootModuleMock();
    await startModugoMock(module: module);

    final routes = await module.configureRoutes(topLevel: true);
    final profileRoute = routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == '/profile',
    );

    expect(profileRoute.name, equals('profile-root'));
  });
}
