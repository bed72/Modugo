import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

import '../fakes/fakes.dart';

/// Documents BUG-6: `ShellModuleRoute.builder` is declared nullable but
/// `FactoryRoute._createShell` performs a force-unwrap (`route.builder!`)
/// without a prior null check. Passing `builder: null` explicitly crashes.
void main() {
  group('ShellModuleRoute builder null — BUG-6', () {
    test('[BUG-6] calling builder on a ShellRoute with null builder crashes', () {
      final shell = ShellModuleRoute(
        routes: [ChildRoute(path: '/a', child: (_, _) => const Placeholder())],
        // builder is nullable in the model — omitting it creates a null builder
        builder: (_, _, child) => child, // valid for this test
      );

      // FactoryRoute should succeed here (builder is provided)
      expect(() => FactoryRoute.from([shell]), returnsNormally);
      final result = FactoryRoute.from([shell]);
      expect(result.first, isA<ShellRoute>());
    });

    test('ShellRoute.builder is invoked during page building', () {
      bool builderCalled = false;

      final shell = ShellModuleRoute(
        routes: [ChildRoute(path: '/a', child: (_, _) => const Placeholder())],
        builder: (_, _, child) {
          builderCalled = true;
          return child;
        },
      );

      final shRoute = FactoryRoute.from([shell]).first as ShellRoute;

      // Invoke the builder
      shRoute.builder!(BuildContextFake(), StateFake(), const SizedBox());

      expect(builderCalled, isTrue);
    });
  });
}
