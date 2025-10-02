import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

void main() {
  group('ChildRoute - equality and hashCode', () {
    test('should be equal when all compared fields are equal', () {
      final key = GlobalKey<NavigatorState>();
      final a = ChildRoute(
        name: 'home',
        path: '/home',
        parentNavigatorKey: key,
        transition: TypeTransition.fade,
        child: (_, _) => const Placeholder(),
      );

      final b = ChildRoute(
        name: 'home',
        path: '/home',
        parentNavigatorKey: key,
        transition: TypeTransition.fade,
        child: (_, _) => const Placeholder(),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal if path differs', () {
      final route1 = ChildRoute(
        path: '/a',
        child: (_, _) => const Placeholder(),
      );
      final route2 = ChildRoute(
        path: '/b',
        child: (_, _) => const Placeholder(),
      );

      expect(route1, isNot(equals(route2)));
    });

    test('should not be equal if name differs', () {
      final route1 = ChildRoute(
        path: '/x',
        name: 'one',
        child: (_, _) => const Placeholder(),
      );
      final route2 = ChildRoute(
        path: '/x',
        name: 'two',
        child: (_, _) => const Placeholder(),
      );

      expect(route1, isNot(equals(route2)));
    });

    test('should not be equal if transition differs', () {
      final route1 = ChildRoute(
        path: '/x',
        transition: TypeTransition.fade,
        child: (_, _) => const Placeholder(),
      );
      final route2 = ChildRoute(
        path: '/x',
        transition: TypeTransition.slideLeft,
        child: (_, _) => const Placeholder(),
      );

      expect(route1, isNot(equals(route2)));
    });

    test('should not be equal if navigatorKey differs', () {
      final route1 = ChildRoute(
        path: '/x',
        parentNavigatorKey: GlobalKey(),
        child: (_, _) => const Placeholder(),
      );
      final route2 = ChildRoute(
        path: '/x',
        parentNavigatorKey: GlobalKey(),
        child: (_, _) => const Placeholder(),
      );

      expect(route1, isNot(equals(route2)));
    });
  });

  group('ChildRoute - field assignment', () {
    test('should assign all optional fields correctly', () {
      final key = GlobalKey<NavigatorState>();
      final route = ChildRoute(
        name: 'details',
        path: '/details/:id',
        parentNavigatorKey: key,
        onExit: (_, _) async => true,
        transition: TypeTransition.fade,
        pageBuilder: (_, _) => const MaterialPage(child: Text('Page')),
        child: (_, _) => const Placeholder(),
      );

      expect(route.name, 'details');
      expect(route.child, isNotNull);
      expect(route.onExit, isNotNull);
      expect(route.path, '/details/:id');
      expect(route.pageBuilder, isNotNull);
      expect(route.parentNavigatorKey, key);
      expect(route.transition, TypeTransition.fade);
    });

    test('should handle minimal constructor with only path and child', () {
      final route = ChildRoute(
        path: '/home',
        child: (_, _) => const Placeholder(),
      );

      expect(route.path, '/home');
      expect(route.name, isNull);
      expect(route.onExit, isNull);
      expect(route.transition, isNull);
      expect(route.pageBuilder, isNull);
      expect(route.parentNavigatorKey, isNull);
    });
  });

  group('ChildRoute - guards', () {
    test('should assign guards list correctly', () {
      final guard1 = _GuardAllow();
      final guard2 = _GuardBlock();

      final route = ChildRoute(
        path: '/secure',
        guards: [guard1, guard2],
        child: (_, _) => const Placeholder(),
      );

      expect(route.guards, isNotNull);
      expect(route.guards.length, 2);
      expect(route.guards.first, isA<_GuardAllow>());
      expect(route.guards.last, isA<_GuardBlock>());
    });

    test('should default to empty guards list when not provided', () {
      final route = ChildRoute(
        path: '/open',
        child: (_, _) => const Placeholder(),
      );

      expect(route.guards, isEmpty);
    });

    test('should not affect equality when guards differ', () {
      final a = ChildRoute(
        path: '/route',
        guards: [_GuardAllow()],
        child: (_, _) => const Placeholder(),
      );

      final b = ChildRoute(
        path: '/route',
        guards: [_GuardBlock()],
        child: (_, _) => const Placeholder(),
      );

      expect(a, equals(b));
    });
  });
}

final class _GuardAllow implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}

final class _GuardBlock implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}
