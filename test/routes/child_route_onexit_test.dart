import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';

import '../fakes/fakes.dart';

void main() {
  group('ChildRoute.onExit', () {
    test('ChildRoute stores onExit callback in its field', () {
      bool exitCalled = false;
      final route = ChildRoute(
        path: '/',
        onExit: (context, state) async {
          exitCalled = true;
          return true;
        },
        child: (_, _) => const Placeholder(),
      );

      expect(route.onExit, isNotNull);
      expect(exitCalled, isFalse);
    });

    test(
      'FactoryRoute forwards onExit to the underlying GoRoute (BUG-ONEXIT fixed)',
      () {
        final route = ChildRoute(
          path: '/',
          onExit: (context, state) async => true,
          child: (_, _) => const Placeholder(),
        );

        final goRoute = FactoryRoute.from([route]).first as GoRoute;
        expect(goRoute.onExit, isNotNull);
      },
    );

    test('ChildRoute without onExit produces GoRoute with null onExit', () {
      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());
      final goRoute = FactoryRoute.from([route]).first as GoRoute;

      expect(goRoute.onExit, isNull);
    });

    test('onExit is invoked and returning true allows navigation', () async {
      bool exitCalled = false;
      final route = ChildRoute(
        path: '/',
        onExit: (context, state) async {
          exitCalled = true;
          return true;
        },
        child: (_, _) => const Placeholder(),
      );

      final goRoute = FactoryRoute.from([route]).first as GoRoute;
      final result = await goRoute.onExit!(BuildContextFake(), StateFake());

      expect(exitCalled, isTrue);
      expect(result, isTrue);
    });

    test('onExit returning false blocks navigation', () async {
      bool exitCalled = false;
      final route = ChildRoute(
        path: '/',
        onExit: (context, state) async {
          exitCalled = true;
          return false;
        },
        child: (_, _) => const Placeholder(),
      );

      final goRoute = FactoryRoute.from([route]).first as GoRoute;
      final result = await goRoute.onExit!(BuildContextFake(), StateFake());

      expect(exitCalled, isTrue);
      expect(result, isFalse);
    });
  });
}
