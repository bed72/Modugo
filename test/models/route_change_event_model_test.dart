import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/models/route_change_event_model.dart';

void main() {
  group('RouteChangedEventModel', () {
    test('stores the route value', () {
      const model = RouteChangedEventModel('/home');
      expect(model.value, '/home');
    });

    test('equal when value matches', () {
      const a = RouteChangedEventModel('/home');
      const b = RouteChangedEventModel('/home');

      expect(a, equals(b));
    });

    test('not equal when value differs', () {
      const a = RouteChangedEventModel('/home');
      const b = RouteChangedEventModel('/profile');

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = RouteChangedEventModel('/home');
      const b = RouteChangedEventModel('/home');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('different values produce different hashCodes', () {
      const a = RouteChangedEventModel('/home');
      const b = RouteChangedEventModel('/other');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('toString includes the location value', () {
      const model = RouteChangedEventModel('/home');
      expect(model.toString(), contains('/home'));
    });

    test('is immutable — const constructor', () {
      const model = RouteChangedEventModel('/test');
      expect(model, isNotNull);
    });
  });
}
