import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules/modules_mock.dart';

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
}
