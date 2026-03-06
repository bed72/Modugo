import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/extensions/go_router_state_extension.dart';

void main() {
  group('GoRouterStateExtension - getExtra', () {
    test('should return extra cast to correct type', () {
      final state = _StateFake(path: '/', extra: 'hello');

      expect(state.getExtra<String>(), 'hello');
    });

    test('should return null when extra is null', () {
      final state = _StateFake(path: '/');

      expect(state.getExtra<String>(), isNull);
    });

    test('should return extra as Map when passed a Map', () {
      final state = _StateFake(path: '/', extra: {'key': 'value'});

      expect(state.getExtra<Map<String, dynamic>>(), {'key': 'value'});
    });
  });

  group('GoRouterStateExtension - isCurrentRoute', () {
    test('should return true when route name matches', () {
      final state = _StateFake(path: '/', routeName: 'dashboard');

      expect(state.isCurrentRoute('dashboard'), isTrue);
    });

    test('should return false when route name does not match', () {
      final state = _StateFake(path: '/', routeName: 'home');

      expect(state.isCurrentRoute('dashboard'), isFalse);
    });

    test('should return false when route name is null', () {
      final state = _StateFake(path: '/');

      expect(state.isCurrentRoute('dashboard'), isFalse);
    });
  });

  group('GoRouterStateExtension - effectivePath', () {
    test('should return path from extra map when available', () {
      final state = _StateFake(
        path: '/fallback',
        extra: {'path': '/from-extra'},
      );

      expect(state.effectivePath, '/from-extra');
    });

    test('should fallback to uri path when extra is not a map', () {
      final state = _StateFake(path: '/fallback', extra: 'not-a-map');

      expect(state.effectivePath, '/fallback');
    });

    test('should fallback to uri path when extra map has no path key', () {
      final state = _StateFake(path: '/fallback', extra: {'other': 'value'});

      expect(state.effectivePath, '/fallback');
    });

    test('should fallback to uri path when extra is null', () {
      final state = _StateFake(path: '/fallback');

      expect(state.effectivePath, '/fallback');
    });
  });

  group('GoRouterStateExtension - isInitialRoute', () {
    test('should return true when matchedLocation is root', () {
      final state = _StateFake(path: '/', matchedLocation: '/');

      expect(state.isInitialRoute, isTrue);
    });

    test('should return false when matchedLocation is not root', () {
      final state = _StateFake(path: '/home', matchedLocation: '/home');

      expect(state.isInitialRoute, isFalse);
    });
  });

  group('GoRouterStateExtension - locationSegments', () {
    test('should return path segments as list', () {
      final state = _StateFake(path: '/profile/settings');

      expect(state.locationSegments, ['profile', 'settings']);
    });

    test('should return empty list for root path', () {
      final state = _StateFake(path: '/');

      expect(state.locationSegments, isEmpty);
    });
  });

  group('GoRouterStateExtension - getPathParam', () {
    test('should return path parameter value when exists', () {
      final state = _StateFake(path: '/user/42', pathParams: {'id': '42'});

      expect(state.getPathParam('id'), '42');
    });

    test('should return null when path parameter does not exist', () {
      final state = _StateFake(path: '/user/42', pathParams: {'id': '42'});

      expect(state.getPathParam('slug'), isNull);
    });
  });

  group('GoRouterStateExtension - query param helpers', () {
    test('should return string query param', () {
      final state = _StateFake(path: '/search?q=flutter');

      expect(state.getStringQueryParam('q'), 'flutter');
    });

    test('should return null for missing string query param', () {
      final state = _StateFake(path: '/search');

      expect(state.getStringQueryParam('q'), isNull);
    });

    test('should return int query param when parsable', () {
      final state = _StateFake(path: '/list?page=3');

      expect(state.getIntQueryParam('page'), 3);
    });

    test('should return null for non-parsable int query param', () {
      final state = _StateFake(path: '/list?page=abc');

      expect(state.getIntQueryParam('page'), isNull);
    });

    test('should return null for missing int query param', () {
      final state = _StateFake(path: '/list');

      expect(state.getIntQueryParam('page'), isNull);
    });

    test('should return true for bool query param with value true', () {
      final state = _StateFake(path: '/filter?active=true');

      expect(state.getBoolQueryParam('active'), isTrue);
    });

    test('should return false for bool query param with value false', () {
      final state = _StateFake(path: '/filter?active=false');

      expect(state.getBoolQueryParam('active'), isFalse);
    });

    test('should return false for bool query param with non-true value', () {
      final state = _StateFake(path: '/filter?active=yes');

      expect(state.getBoolQueryParam('active'), isFalse);
    });

    test('should return null for missing bool query param', () {
      final state = _StateFake(path: '/filter');

      expect(state.getBoolQueryParam('active'), isNull);
    });

    test('should handle case-insensitive bool query param', () {
      final state = _StateFake(path: '/filter?active=TRUE');

      expect(state.getBoolQueryParam('active'), isTrue);
    });
  });

  group('GoRouterStateExtension - argumentsOrThrow', () {
    test('should return extra when type matches', () {
      final state = _StateFake(path: '/', extra: 'data');

      expect(state.argumentsOrThrow<String>(), 'data');
    });

    test('should throw when extra type does not match', () {
      final state = _StateFake(path: '/', extra: 123);

      expect(() => state.argumentsOrThrow<String>(), throwsA(isA<Exception>()));
    });

    test('should throw when extra is null', () {
      final state = _StateFake(path: '/');

      expect(() => state.argumentsOrThrow<String>(), throwsA(isA<Exception>()));
    });
  });
}

final class _StateFake extends Fake implements GoRouterState {
  _StateFake({
    required String path,
    this.extra,
    this.routeName,
    String? matchedLocation,
    Map<String, String> pathParams = const {},
  }) : _uri = Uri.parse(path),
       _matchedLocation = matchedLocation ?? Uri.parse(path).path,
       _pathParams = pathParams;

  final Uri _uri;
  final String _matchedLocation;
  final Map<String, String> _pathParams;

  @override
  final Object? extra;

  final String? routeName;

  @override
  Uri get uri => _uri;

  @override
  String get name => routeName ?? '';

  @override
  String get matchedLocation => _matchedLocation;

  @override
  Map<String, String> get pathParameters => _pathParams;
}
