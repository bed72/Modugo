import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/transitions/transition.dart';

void main() {
  test('should create a valid instance with required parameters', () {
    final route = ChildRoute('/home', child: (_, __) => const Text('Home'));

    expect(route.path, '/home');
    expect(route.name, isNull);
    expect(route.transition, isNull);
    expect(route.parentNavigatorKey, isNull);
  });

  test('should support equality via Equatable', () {
    final route1 = ChildRoute(
      '/home',
      name: 'home',
      transition: TypeTransition.fade,
      parentNavigatorKey: GlobalKey<NavigatorState>(),
      child: (_, __) => const Text('A'),
    );

    final route2 = ChildRoute(
      '/home',
      name: 'home',
      transition: TypeTransition.fade,
      parentNavigatorKey: route1.parentNavigatorKey,
      child: (_, __) => const Text('B'),
    );

    expect(route1, equals(route2));
    expect(route1.hashCode, equals(route2.hashCode));
  });

  test('should not be equal if path or name differs', () {
    final key = GlobalKey<NavigatorState>();

    final route1 = ChildRoute(
      '/a',
      name: 'routeA',
      parentNavigatorKey: key,
      child: (_, __) => const SizedBox(),
    );

    final route2 = ChildRoute(
      '/b',
      name: 'routeB',
      parentNavigatorKey: key,
      child: (_, __) => const SizedBox(),
    );

    expect(route1 == route2, isFalse);
  });
}
