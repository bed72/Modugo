import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Overrides [defaultTargetPlatform] for the duration of a single test.
void _overridePlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
}

/// Resets the platform override and Modugo state after each test.
void _reset() {
  debugDefaultTargetPlatformOverride = null;
  Modugo.resetForTesting();
  GetIt.instance.reset();
}

/// Builds a [GoRoute.pageBuilder] output for a [ChildRoute] so we can
/// inspect the [Page] type without a full widget tree.
Page<dynamic> _buildPage(ChildRoute route, {GoRouterState? state}) {
  final s = state ?? StateFake();
  final goRoute = FactoryRoute.from([route]).first as GoRoute;
  return goRoute.pageBuilder!(BuildContextFake(), s);
}

/// Same as [_buildPage] but for a [ModuleRoute].
Page<dynamic> _buildModulePage(_SimpleModule module) {
  final route = ModuleRoute(path: '/mod', module: module);
  final goRoute = FactoryRoute.from([route]).first as GoRoute;
  return goRoute.pageBuilder!(BuildContextFake(), StateFake());
}

// ---------------------------------------------------------------------------
// Fake modules
// ---------------------------------------------------------------------------

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Text('Root')),
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(_reset);

  // -------------------------------------------------------------------------
  // TypeTransition.native
  // -------------------------------------------------------------------------

  group('TypeTransition.native', () {
    test('returns CupertinoPage on iOS', () async {
      _overridePlatform(TargetPlatform.iOS);
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        child: (_, _) => const Placeholder(),
      );

      final page = _buildPage(route);
      expect(page, isA<CupertinoPage>());
    });

    test('returns MaterialPage on Android', () async {
      _overridePlatform(TargetPlatform.android);
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        child: (_, _) => const Placeholder(),
      );

      final page = _buildPage(route);
      expect(page, isA<MaterialPage>());
    });

    test('returns MaterialPage on macOS', () async {
      _overridePlatform(TargetPlatform.macOS);
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        child: (_, _) => const Placeholder(),
      );

      final page = _buildPage(route);
      expect(page, isA<MaterialPage>());
    });

    test('returns MaterialPage on web (fuchsia proxy)', () async {
      _overridePlatform(TargetPlatform.fuchsia);
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        child: (_, _) => const Placeholder(),
      );

      final page = _buildPage(route);
      expect(page, isA<MaterialPage>());
    });

    test('native wins over iosGestureEnabled: false', () async {
      // TypeTransition.native has highest precedence.
      _overridePlatform(TargetPlatform.iOS);
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        iosGestureEnabled: false, // explicit false, but native wins
        child: (_, _) => const Placeholder(),
      );

      final page = _buildPage(route);
      expect(page, isA<CupertinoPage>());
    });
  });

  // -------------------------------------------------------------------------
  // Global enableIOSGestureNavigation — iOS
  // -------------------------------------------------------------------------

  group('enableIOSGestureNavigation: true (default) on iOS', () {
    setUp(() => _overridePlatform(TargetPlatform.iOS));

    test('returns CupertinoPage for ChildRoute with no transition', () async {
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());

      expect(_buildPage(route), isA<CupertinoPage>());
    });

    test('returns CupertinoPage for ModuleRoute', () async {
      await Modugo.configure(module: _SimpleModule());
      expect(_buildModulePage(_SimpleModule()), isA<CupertinoPage>());
    });

    test('preserves pageKey on CupertinoPage', () async {
      await Modugo.configure(module: _SimpleModule());

      final state = StateFake();
      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());

      final page = _buildPage(route, state: state);
      expect((page as CupertinoPage).key, equals(state.pageKey));
    });
  });

  group('enableIOSGestureNavigation: false on iOS', () {
    setUp(() => _overridePlatform(TargetPlatform.iOS));

    test('returns CustomTransitionPage when global is false', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        enableIOSGestureNavigation: false,
      );

      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());

      expect(_buildPage(route), isA<CustomTransitionPage>());
    });
  });

  // -------------------------------------------------------------------------
  // Global flag does NOT affect non-iOS
  // -------------------------------------------------------------------------

  group('enableIOSGestureNavigation on non-iOS', () {
    test(
      'returns CustomTransitionPage on Android even with global true',
      () async {
        _overridePlatform(TargetPlatform.android);
        await Modugo.configure(
          module: _SimpleModule(),
          enableIOSGestureNavigation: true,
        );

        final route = ChildRoute(
          path: '/',
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test('returns CustomTransitionPage on Linux with global true', () async {
      _overridePlatform(TargetPlatform.linux);
      await Modugo.configure(
        module: _SimpleModule(),
        enableIOSGestureNavigation: true,
      );

      final route = ChildRoute(path: '/', child: (_, _) => const Placeholder());

      expect(_buildPage(route), isA<CustomTransitionPage>());
    });
  });

  // -------------------------------------------------------------------------
  // Per-route iosGestureEnabled override
  // -------------------------------------------------------------------------

  group('per-route iosGestureEnabled override', () {
    setUp(() => _overridePlatform(TargetPlatform.iOS));

    test(
      'iosGestureEnabled: false overrides global true → CustomTransitionPage',
      () async {
        await Modugo.configure(module: _SimpleModule()); // global = true

        final route = ChildRoute(
          path: '/',
          iosGestureEnabled: false,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test(
      'iosGestureEnabled: true overrides global false → CupertinoPage',
      () async {
        await Modugo.configure(
          module: _SimpleModule(),
          enableIOSGestureNavigation: false,
        );

        final route = ChildRoute(
          path: '/',
          iosGestureEnabled: true,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CupertinoPage>());
      },
    );

    test(
      'iosGestureEnabled: null inherits global true → CupertinoPage',
      () async {
        await Modugo.configure(module: _SimpleModule()); // global = true

        final route = ChildRoute(
          path: '/',
          // iosGestureEnabled omitted → null → inherits global
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CupertinoPage>());
      },
    );

    test(
      'iosGestureEnabled: null inherits global false → CustomTransitionPage',
      () async {
        await Modugo.configure(
          module: _SimpleModule(),
          enableIOSGestureNavigation: false,
        );

        final route = ChildRoute(
          path: '/',
          // iosGestureEnabled omitted → null → inherits global
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );
  });

  // -------------------------------------------------------------------------
  // Explicit custom transition bypasses gesture flag
  // -------------------------------------------------------------------------

  group('explicit custom transition bypasses iOS gesture', () {
    setUp(() => _overridePlatform(TargetPlatform.iOS));

    test(
      'TypeTransition.fade → CustomTransitionPage even with global true',
      () async {
        await Modugo.configure(module: _SimpleModule()); // global = true

        final route = ChildRoute(
          path: '/',
          transition: TypeTransition.fade,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test(
      'TypeTransition.slideLeft → CustomTransitionPage with global true',
      () async {
        await Modugo.configure(module: _SimpleModule());

        final route = ChildRoute(
          path: '/',
          transition: TypeTransition.slideLeft,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test(
      'TypeTransition.scale → CustomTransitionPage with global true',
      () async {
        await Modugo.configure(module: _SimpleModule());

        final route = ChildRoute(
          path: '/',
          transition: TypeTransition.scale,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test(
      'explicit transition + iosGestureEnabled: true → CustomTransitionPage',
      () async {
        // iosGestureEnabled: true is ignored when explicit transition is set
        await Modugo.configure(module: _SimpleModule());

        final route = ChildRoute(
          path: '/',
          transition: TypeTransition.rotation,
          iosGestureEnabled: true,
          child: (_, _) => const Placeholder(),
        );

        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );
  });

  // -------------------------------------------------------------------------
  // StatefulShellModuleRoute
  // -------------------------------------------------------------------------

  group('StatefulShellModuleRoute respects enableIOSGestureNavigation', () {
    test(
      'returns CupertinoPage for branches on iOS with global true',
      () async {
        _overridePlatform(TargetPlatform.iOS);
        await Modugo.configure(module: _SimpleModule());

        final shell = StatefulShellModuleRoute(
          builder: (_, _, shell) => shell,
          routes: [
            ModuleRoute(path: '/a', module: _SimpleModule()),
            ModuleRoute(path: '/b', module: _SimpleModule()),
          ],
        );

        final result = FactoryRoute.from([shell]);
        final shellRoute = result.first as StatefulShellRoute;

        // Each branch should have a GoRoute with a CupertinoPage pageBuilder.
        final firstBranchRoute =
            shellRoute.branches.first.routes.first as GoRoute;
        final page = firstBranchRoute.pageBuilder!(
          BuildContextFake(),
          StateFake(),
        );

        expect(page, isA<CupertinoPage>());
      },
    );

    test(
      'returns CustomTransitionPage for branches on iOS with global false',
      () async {
        _overridePlatform(TargetPlatform.iOS);
        await Modugo.configure(
          module: _SimpleModule(),
          enableIOSGestureNavigation: false,
        );

        final shell = StatefulShellModuleRoute(
          builder: (_, _, shell) => shell,
          routes: [ModuleRoute(path: '/a', module: _SimpleModule())],
        );

        final result = FactoryRoute.from([shell]);
        final shellRoute = result.first as StatefulShellRoute;
        final firstBranchRoute =
            shellRoute.branches.first.routes.first as GoRoute;
        final page = firstBranchRoute.pageBuilder!(
          BuildContextFake(),
          StateFake(),
        );

        expect(page, isA<CustomTransitionPage>());
      },
    );
  });

  // -------------------------------------------------------------------------
  // Precedence: native > per-route > global > default
  // -------------------------------------------------------------------------

  group('full precedence chain', () {
    setUp(() => _overridePlatform(TargetPlatform.iOS));

    test('native > iosGestureEnabled: false > global false', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        enableIOSGestureNavigation: false,
      );

      final route = ChildRoute(
        path: '/',
        transition: TypeTransition.native,
        iosGestureEnabled: false,
        child: (_, _) => const Placeholder(),
      );

      // native always wins
      expect(_buildPage(route), isA<CupertinoPage>());
    });

    test(
      'explicit transition > iosGestureEnabled: true > global true',
      () async {
        await Modugo.configure(module: _SimpleModule());

        final route = ChildRoute(
          path: '/',
          transition: TypeTransition.slideUp,
          iosGestureEnabled: true,
          child: (_, _) => const Placeholder(),
        );

        // explicit transition wins over gesture flags
        expect(_buildPage(route), isA<CustomTransitionPage>());
      },
    );

    test('per-route false > global true', () async {
      await Modugo.configure(module: _SimpleModule());

      final route = ChildRoute(
        path: '/',
        iosGestureEnabled: false,
        child: (_, _) => const Placeholder(),
      );

      expect(_buildPage(route), isA<CustomTransitionPage>());
    });

    test('per-route true > global false', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        enableIOSGestureNavigation: false,
      );

      final route = ChildRoute(
        path: '/',
        iosGestureEnabled: true,
        child: (_, _) => const Placeholder(),
      );

      expect(_buildPage(route), isA<CupertinoPage>());
    });
  });
}
