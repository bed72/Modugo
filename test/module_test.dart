import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules_mock.dart';

void main() {
  setUpAll(() async {
    await startModugoMock(module: OtherModuleMock());
  });

  test('Module.configureRoutes creates valid RouteBase list', () {
    final module = OtherModuleMock();
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
  });

  test('Module.adjustRoute works as expected', () {
    final module = OtherModuleMock();

    expect(module.adjustRoute('/'), '/');
    expect(module.adjustRoute('/:id'), '/');
    expect(module.adjustRoute('/other'), '/other');
  });

  test('Module.buildPath normalizes paths correctly', () {
    final module = OtherModuleMock();

    expect(module.buildPath('/'), '/');
    expect(module.buildPath('/abc/'), '/abc');
    expect(module.buildPath('/abc'), '/abc');
    expect(module.buildPath('/abc//'), '/abc');
    expect(module.buildPath('/abc////xyz/'), '/abc/xyz');
  });
}
