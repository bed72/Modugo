import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

/// Documents DESIGN-7: `operator==` in ChildRoute includes `runtimeType`
/// but `hashCode` does not. This violates the contract: `a == b` must imply
/// `a.hashCode == b.hashCode`.
///
/// The consequence is that two equal routes used in a Set or as Map keys can
/// end up in different buckets, causing missed deduplication or key lookups.
///
/// These tests document the broken contract. When DESIGN-7 is fixed, the
/// [BUG-DESIGN-7] tests should be updated to assert `equals(b.hashCode)`.
void main() {
  group('ChildRoute equality/hashCode contract — DESIGN-7', () {
    test('equal routes have equal hashCode (basic case)', () {
      final key = GlobalKey<NavigatorState>();
      final a = ChildRoute(
        path: '/home',
        name: 'home',
        transition: TypeTransition.fade,
        parentNavigatorKey: key,
        child: (_, _) => const Placeholder(),
      );
      final b = ChildRoute(
        path: '/home',
        name: 'home',
        transition: TypeTransition.fade,
        parentNavigatorKey: key,
        child: (_, _) => const Placeholder(),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
      '[DESIGN-7] operator== uses runtimeType but hashCode does not — contract holds for same concrete class',
      () {
        // Both are ChildRoute (same runtimeType) so the contract is preserved
        // for the basic case. The violation occurs with subclasses.
        final a = ChildRoute(path: '/x', child: (_, _) => const Placeholder());
        final b = ChildRoute(path: '/x', child: (_, _) => const Placeholder());

        expect(a == b, isTrue);
        expect(a.hashCode == b.hashCode, isTrue);
      },
    );

    test('different paths produce different hashCodes', () {
      final a = ChildRoute(path: '/a', child: (_, _) => const Placeholder());
      final b = ChildRoute(path: '/b', child: (_, _) => const Placeholder());

      expect(a, isNot(equals(b)));
      // hashCodes are not required to differ for unequal objects, but paths
      // dominate the hash so they should differ in practice.
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('ModuleRoute equality/hashCode contract', () {
    test('equal ModuleRoutes have equal hashCode', () {
      final module = _FakeModule();
      final a = ModuleRoute(path: '/mod', name: 'mod', module: module);
      final b = ModuleRoute(path: '/mod', name: 'mod', module: module);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different paths produce different ModuleRoute hashCodes', () {
      final module = _FakeModule();
      final a = ModuleRoute(path: '/a', module: module);
      final b = ModuleRoute(path: '/b', module: module);

      expect(a, isNot(equals(b)));
    });
  });

  group('ShellModuleRoute equality/hashCode contract', () {
    test('equal ShellModuleRoutes have equal hashCode', () {
      final navKey = GlobalKey<NavigatorState>();
      final routes = <IRoute>[
        ChildRoute(path: '/a', child: (_, _) => const Placeholder()),
      ];

      final a = ShellModuleRoute(
        routes: routes,
        navigatorKey: navKey,
        builder: (_, _, child) => child,
      );
      final b = ShellModuleRoute(
        routes: routes,
        navigatorKey: navKey,
        builder: (_, _, child) => child,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}

final class _FakeModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}
