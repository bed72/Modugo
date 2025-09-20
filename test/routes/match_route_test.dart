import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/match_route.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

void main() {
  group('MatchRoute', () {
    test('stores route and params correctly', () {
      final route = _DummyModule();
      final result = MatchRoute(route: route, params: {'id': '123'});

      expect(result.route, route);
      expect(result.params, {'id': '123'});
    });

    test('== returns false for different routes', () {
      final a = MatchRoute(route: _DummyModule(), params: {'id': '1'});
      final b = MatchRoute(route: _DummyModule(), params: {'id': '1'});

      expect(identical(a.route, b.route), isFalse);
      expect(a == b, isFalse);
    });

    test('== returns false for different params', () {
      final route = _DummyModule();
      final a = MatchRoute(route: route, params: {'id': '1'});
      final b = MatchRoute(route: route, params: {'id': '2'});

      expect(a == b, isFalse);
    });

    test('toString includes route and params', () {
      final result = MatchRoute(
        route: _DummyModule(),
        params: {'key': 'value'},
      );

      expect(result.toString(), contains('_DummyModule'));
      expect(result.toString(), contains('{key: value}'));
    });
  });
}

final class _DummyModule implements IRoute {
  const _DummyModule();

  @override
  String toString() => '_DummyModule';
}
