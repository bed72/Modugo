import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/routes/models/route_access_model.dart';

void main() {
  test('should be equal when path and branch are the same', () {
    final a = RouteAccessModel('/cart', '1');
    final b = RouteAccessModel('/cart', '1');
    expect(a, equals(b));
  });

  test('should not be equal when paths are different', () {
    final a = RouteAccessModel('/cart', '1');
    final b = RouteAccessModel('/home', '1');
    expect(a, isNot(equals(b)));
  });

  test('should not be equal when branches are different', () {
    final a = RouteAccessModel('/cart', '1');
    final b = RouteAccessModel('/cart', '2');
    expect(a, isNot(equals(b)));
  });

  test('should not be equal when one branch is null', () {
    final a = RouteAccessModel('/cart', null);
    final b = RouteAccessModel('/cart', '1');
    expect(a, isNot(equals(b)));
  });

  test('should be equal when branch is null or not provided', () {
    final a = RouteAccessModel('/cart');
    final b = RouteAccessModel('/cart', null);
    expect(a, equals(b));
  });

  test('should have same hashCode when equal', () {
    final a = RouteAccessModel('/cart', '1');
    final b = RouteAccessModel('/cart', '1');
    expect(a.hashCode, equals(b.hashCode));
  });

  test('should have different hashCodes when not equal', () {
    final a = RouteAccessModel('/cart', '1');
    final b = RouteAccessModel('/cart', '2');
    expect(a.hashCode, isNot(equals(b.hashCode)));
  });
}
