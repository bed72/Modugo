import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

void main() {
  group('StatefulShellModuleRoute - equality and hashCode', () {
    test('should be equal when routes and builder match', () {
      builder(BuildContext c, GoRouterState s, StatefulNavigationShell n) =>
          const Placeholder();

      final sharedModule = _DummyModule();

      final a = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute(path: '/home', module: sharedModule)],
      );

      final b = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute(path: '/home', module: sharedModule)],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal if builder changes', () {
      final a = StatefulShellModuleRoute(
        builder: (_, _, _) => const Placeholder(),
        routes: [ModuleRoute(path: '/home', module: _DummyModule())],
      );

      final b = StatefulShellModuleRoute(
        builder: (_, _, _) => const Text('Different'),
        routes: [ModuleRoute(path: '/home', module: _DummyModule())],
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('StatefulShellModuleRoute - route generation', () {
    test('should throw if route type is unsupported', () {
      final route = StatefulShellModuleRoute(
        routes: [_UnsupportedRoute()],
        builder: (_, _, _) => const Placeholder(),
      );

      expect(() => route.toRoute(path: '/'), throwsA(isA<UnsupportedError>()));
    });
  });

  test(
    'StatefulShellModuleRoute applies guard redirect from ModuleRoute inside branch',
    () async {
      final module = _StatefulShellGuardedModule();

      final routes = module.configureRoutes();
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedBranch = shell.branches.first;
      final guardedRoute = guardedBranch.routes.whereType<GoRoute>().first;

      final redirectFn = guardedRoute.redirect!;
      final result = await redirectFn(BuildContextFake(), StateFake());

      expect(result, '/not-allowed');
    },
  );

  test(
    'applies redirect from ChildRoute with guards in StatefulShellModuleRoute',
    () async {
      final module = _StatefulShellWithChildGuardModule();

      final routes = module.configureRoutes();
      final shell = routes.whereType<StatefulShellRoute>().first;

      final route = shell.branches.first.routes.whereType<GoRoute>().first;
      final redirectFn = route.redirect!;
      final result = await redirectFn(BuildContextFake(), StateFake());

      expect(result, '/denied');
    },
  );

  test(
    'only first guard result is respected in ChildRoute inside StatefulShell',
    () async {
      final module = _StatefulShellWithMultipleGuardsModule();

      final routes = module.configureRoutes();
      final shell = routes.whereType<StatefulShellRoute>().first;

      final route = shell.branches.first.routes.whereType<GoRoute>().first;
      final redirectFn = route.redirect!;
      final result = await redirectFn(BuildContextFake(), StateFake());

      expect(result, '/first');
    },
  );

  test(
    'StatefulShellModuleRoute applies guard when ModuleRoute path is "/"',
    () async {
      final module = _StatefulShellGuardedModule();

      final routes = module.configureRoutes();
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedRoute =
          shell.branches.first.routes.whereType<GoRoute>().first;
      final result = await guardedRoute.redirect!(
        BuildContextFake(),
        StateFake(),
      );

      expect(result, '/not-allowed');
    },
  );

  test('should be equal even if guards differ in ModuleRoute', () {
    builder(_, _, _) => const Placeholder();
    final sharedModule = _DummyModule();

    final baseRoute = ModuleRoute(path: '/home', module: sharedModule);

    final a = StatefulShellModuleRoute(builder: builder, routes: [baseRoute]);

    final b = StatefulShellModuleRoute(
      builder: builder,
      routes: [ModuleRoute(path: '/home', module: sharedModule)],
    );

    expect(a, equals(b));
  });

  test(
    'StatefulShellModuleRoute does not force childRoute.redirect when ModuleRoute path is not "/"',
    () async {
      final module = _StatefulShellGuardedModuleWithRealPath();

      final routes = module.configureRoutes();
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedRoute = shell.branches.first.routes
          .whereType<GoRoute>()
          .firstWhere(
            (_) => true,
            orElse: () => throw TestFailure('No GoRoute found in first branch'),
          );

      final result = await guardedRoute.redirect!(
        BuildContextFake(),
        StateFake(),
      );

      expect(result, '/not-allowed');
    },
  );

  group('StatefulShellModuleRoute - navigation key', () {
    test('toRoute generates StatefulShellRoute.indexedStack', () {
      final route = StatefulShellModuleRoute(
        builder: (_, _, _) => const Placeholder(),
        routes: [ModuleRoute(path: '/', module: _DummyModule())],
      );

      final result = route.toRoute(path: '/');

      expect(result, isA<StatefulShellRoute>());
    });
    test('builds StatefulShellModuleRoute with correct config', () {
      final key = GlobalKey<StatefulNavigationShellState>();
      final parentKey = GlobalKey<NavigatorState>();

      final route = StatefulShellModuleRoute(
        key: key,
        parentNavigatorKey: parentKey,
        restorationScopeId: 'shell-scope',
        builder: (_, _, _) => const Placeholder(),
        routes: [
          ModuleRoute(path: '/', module: _DummyModule()),
          ChildRoute(path: '/profile', child: (_, _) => const Placeholder()),
        ],
      );

      expect(route.key, key);
      expect(route.parentNavigatorKey, parentKey);
      expect(route.restorationScopeId, 'shell-scope');
    });
  });
}

final class _UnsupportedRoute implements IRoute {}

final class _BlockGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/not-allowed';
}

final class _ChildBlockGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/denied';
}

final class _GuardA implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/first';
}

final class _GuardB implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/second';
}

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Text('Profile')),
  ];
}

final class _DummyModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/home', child: (_, _) => const Placeholder()),
  ];
}

final class _GuardedChildModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      guards: [_BlockGuard()],
      child: (_, _) => const Placeholder(),
      redirect: (context, state) => '/not-allowed',
    ),
  ];
}

final class _GuardedChildModuleWithRealPath extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/guarded',
      child: (_, _) => const SizedBox.shrink(),
      redirect: (context, state) => '/not-allowed',
    ),
  ];
}

final class _ModuleWithGuardedChild extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      guards: [_ChildBlockGuard()],
      child: (_, _) => const Placeholder(),
    ),
  ];
}

final class _ModuleWithMultipleGuards extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      guards: [_GuardA(), _GuardB()],
      child: (_, _) => const Placeholder(),
    ),
  ];
}

final class _StatefulShellWithChildGuardModule extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [ModuleRoute(path: '/home', module: _ModuleWithGuardedChild())],
    ),
  ];
}

final class _StatefulShellWithMultipleGuardsModule extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [ModuleRoute(path: '/home', module: _ModuleWithMultipleGuards())],
    ),
  ];
}

final class _StatefulShellGuardedModule extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [
        ModuleRoute(path: '/home', module: _GuardedChildModule()),
        ModuleRoute(path: '/profile', module: _SimpleModule()),
      ],
    ),
  ];
}

final class _StatefulShellGuardedModuleWithRealPath extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [
        ModuleRoute(
          path: '/guarded',
          module: _GuardedChildModuleWithRealPath(),
        ),
      ],
    ),
  ];
}
