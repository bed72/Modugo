import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/models/route_pattern_model.dart';

void main() {
  group('RoutePatternModel', () {
    test('creates RegExp and paramNames correctly via from()', () {
      final pattern = RoutePatternModel.from(
        r'^/user/(\d+)/profile$',
        paramNames: ['id'],
      );

      expect(pattern.regex.pattern, '^/user/(\\d+)/profile\$');
      expect(pattern.paramNames, ['id']);
    });

    test('extractParams returns correct values on match', () {
      final pattern = RoutePatternModel.from(
        r'^/product/(\w+)/details/(\d+)$',
        paramNames: ['slug', 'id'],
      );
      final result = pattern.extractParams('/product/sneaker/details/42');

      expect(result, {'slug': 'sneaker', 'id': '42'});
    });

    test('extractParams returns empty map on no match', () {
      final pattern = RoutePatternModel.from(
        r'^/user/(\d+)$',
        paramNames: ['id'],
      );
      final result = pattern.extractParams('/invalid/route');

      expect(result, isEmpty);
    });

    test('== returns true for equal pattern and param names', () {
      final a = RoutePatternModel.from(r'^/x/(\w+)$', paramNames: ['x']);
      final b = RoutePatternModel.from(r'^/x/(\w+)$', paramNames: ['x']);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== returns false for different param names or regex', () {
      final a = RoutePatternModel.from(r'^/x/(\w+)$', paramNames: ['x']);
      final b = RoutePatternModel.from(r'^/x/(\w+)$', paramNames: ['y']);
      final c = RoutePatternModel.from(r'^/y/(\w+)$', paramNames: ['x']);

      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });

    test('toString provides debug-friendly output', () {
      final pattern = RoutePatternModel.from(
        r'^/user/(\d+)$',
        paramNames: ['id'],
      );
      expect(
        pattern.toString(),
        'RoutePatternModel(regex: ^/user/(\\d+)\$, paramNames: [id])',
      );
    });
  });
}
