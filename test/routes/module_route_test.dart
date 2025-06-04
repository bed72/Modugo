import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/module_route.dart';

import '../mocks/modules_mock.dart';

void main() {
  group('ModuleRoute', () {
    test('should instantiate with required and optional parameters', () {
      final module = InnerModuleMock();
      final route = ModuleRoute('/home', module: module, name: 'homeRoute');

      expect(route.path, '/home');
      expect(route.module, module);
      expect(route.name, 'homeRoute');
    });

    test('should instantiate without optional name parameter', () {
      final module = InnerModuleMock();
      final route = ModuleRoute('/dashboard', module: module);

      expect(route.path, '/dashboard');
      expect(route.module, module);
      expect(route.name, isNull);
    });

    test('should compare equality correctly', () {
      final moduleA = InnerModuleMock();
      final moduleB = InnerModuleMock();

      final route1 = ModuleRoute('/home', module: moduleA, name: 'route');
      final route2 = ModuleRoute('/home', module: moduleA, name: 'route');
      final route3 = ModuleRoute('/home', module: moduleB, name: 'route');
      final route4 = ModuleRoute('/profile', module: moduleA, name: 'route');

      expect(route1, equals(route2));
      expect(route1 == route2, isTrue);

      expect(route1 == route3, isFalse);

      expect(route1 == route4, isFalse);
    });
  });
}
