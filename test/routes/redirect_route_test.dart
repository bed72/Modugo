import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/redirect_route.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

import '../fakes/fakes.dart';

void main() {
  group('RedirectRoute', () {
    test('stores path, name, guards, and redirect function', () async {
      final route = RedirectRoute(
        path: '/old/:id',
        name: 'test-route',
        redirect: (_, _) async => '/new/123',
      );

      expect(route.guards, isEmpty);
      expect(route.path, '/old/:id');
      expect(route.name, 'test-route');

      final result = await route.redirect(BuildContextFake(), StateFake());
      expect(result, '/new/123');
    });

    test('executes redirect function correctly', () async {
      final route = RedirectRoute(path: '/from', redirect: (_, state) => '/to');

      final result = await route.redirect(BuildContextFake(), StateFake());

      expect(result, '/to');
    });

    test('guards can override redirect', () async {
      final guard = _AllowGuard(redirectPath: '/guarded');
      final _ = RedirectRoute(
        path: '/secure',
        guards: [guard],
        redirect: (_, _) => '/normal',
      );

      final resultFromGuard = await guard(BuildContextFake(), StateFake());

      expect(resultFromGuard, '/guarded');
    });

    test('== and hashCode consider path and name', () {
      final a = RedirectRoute(
        name: 'same',
        path: '/equal',
        redirect: (_, _) => '/target',
      );
      final b = RedirectRoute(
        name: 'same',
        path: '/equal',
        redirect: (_, _) => '/another',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different routes are not equal', () {
      final a = RedirectRoute(path: '/a', name: 'A', redirect: (_, _) => '/x');
      final b = RedirectRoute(path: '/b', name: 'B', redirect: (_, _) => '/y');

      expect(a == b, isFalse);
    });
  });
}

final class _AllowGuard implements IGuard {
  final String? redirectPath;
  _AllowGuard({this.redirectPath});
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      redirectPath;
}
