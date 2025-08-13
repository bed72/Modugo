import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/models/route_access_model.dart';

void main() {
  group('RouteAccessModel - equality and hashCode', () {
    test('should be equal when path and branch are the same', () {
      const a = RouteAccessModel('/home', 'main');
      const b = RouteAccessModel('/home', 'main');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal when path is different', () {
      const a = RouteAccessModel('/home', 'main');
      const b = RouteAccessModel('/dashboard', 'main');

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when branch is different', () {
      const a = RouteAccessModel('/home', 'main');
      const b = RouteAccessModel('/home', 'alt');

      expect(a, isNot(equals(b)));
    });

    test('should be equal when both branches are null', () {
      const a = RouteAccessModel('/home');
      const b = RouteAccessModel('/home');

      expect(a, equals(b));
    });

    test('should not be equal when one branch is null and other is not', () {
      const a = RouteAccessModel('/home');
      const b = RouteAccessModel('/home', 'main');

      expect(a, isNot(equals(b)));
    });
  });

  group('RouteAccessModel - toString', () {
    test('should return correct string representation with branch', () {
      const model = RouteAccessModel('/home', 'main');
      expect(model.toString(), equals('RouteAccessModel(/home, main)'));
    });

    test('should return correct string representation without branch', () {
      const model = RouteAccessModel('/home');
      expect(model.toString(), equals('RouteAccessModel(/home, null)'));
    });
  });
}
