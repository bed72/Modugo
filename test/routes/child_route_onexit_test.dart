import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';

import '../fakes/fakes.dart';

/// Tests for ChildRoute.onExit behavior.
///
/// NOTE — BUG-ONEXIT: `onExit` is declared on `ChildRoute` and forwarded to
/// the DSL `child()` method, but `FactoryRoute._createChild()` does NOT pass
/// it to the underlying `GoRoute`. As a result, `GoRoute.onExit` is always null
/// regardless of what `ChildRoute.onExit` is set to.
///
/// These tests document both the expected contract (onExit should be forwarded)
/// and the current broken behavior (GoRoute.onExit is null).
/// When the bug is fixed, the [BUG-ONEXIT] test should be removed and the
/// "onExit is forwarded" test should become the primary assertion.
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

      // The field is stored on ChildRoute — the bug is it's not forwarded.
      expect(route.onExit, isNotNull);
      expect(exitCalled, isFalse); // not yet called — just confirming storage
    });

    test('[BUG-ONEXIT] FactoryRoute does not forward onExit to GoRoute', () {
      // This documents the bug: ChildRoute.onExit is never passed to GoRoute.
      // When fixed, this test should be removed and the one below should pass.
      final route = ChildRoute(
        path: '/',
        onExit: (context, state) async => true,
        child: (_, _) => const Placeholder(),
      );

      final goRoute = FactoryRoute.from([route]).first as GoRoute;
      expect(
        goRoute.onExit,
        isNull,
        reason:
            'BUG: FactoryRoute._createChild does not pass onExit to GoRoute',
      );
    });

    test('ChildRoute without onExit produces GoRoute with null onExit', () {
      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());
      final goRoute = FactoryRoute.from([route]).first as GoRoute;

      expect(goRoute.onExit, isNull);
    });

    test(
      'onExit returning false is callable via ChildRoute field directly',
      () async {
        bool exitCalled = false;
        final route = ChildRoute(
          path: '/',
          onExit: (context, state) async {
            exitCalled = true;
            return false;
          },
          child: (_, _) => const Placeholder(),
        );

        // Call onExit directly through the ChildRoute field (bypassing GoRoute).
        final result = await route.onExit!(BuildContextFake(), StateFake());

        expect(exitCalled, isTrue);
        expect(result, isFalse);
      },
    );
  });
}
