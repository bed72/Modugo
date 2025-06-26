import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  group('StatefulShellModuleRoute - equality and hashCode', () {
    test('should be equal when routes and builder match', () {
      builder(BuildContext c, GoRouterState s, StatefulNavigationShell n) =>
          const Placeholder();

      final sharedModule = _DummyModule();

      final a = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute('/home', module: sharedModule)],
      );

      final b = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute('/home', module: sharedModule)],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal if builder changes', () {
      final a = StatefulShellModuleRoute(
        routes: [ModuleRoute('/home', module: _DummyModule())],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = StatefulShellModuleRoute(
        routes: [ModuleRoute('/home', module: _DummyModule())],
        builder: (_, __, ___) => const Text('Different'),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('StatefulShellModuleRoute - path composition', () {
    test('normalizePath should clean up redundant slashes', () {
      final route = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(route.normalizePath('///settings//home'), '/settings/home');
      expect(route.normalizePath(''), '/');
    });
  });

  group('StatefulShellModuleRoute - route generation', () {
    test('should throw if route type is unsupported', () {
      final route = StatefulShellModuleRoute(
        routes: [_UnsupportedRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(
        () => route.toRoute(path: '/', topLevel: true),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  test(
    'StatefulShellModuleRoute applies guard redirect from ModuleRoute inside branch',
    () async {
      final module = _StatefulShellGuardedModule();

      final routes = module.configureRoutes(topLevel: true);
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedBranch = shell.branches.first;
      final guardedRoute = guardedBranch.routes.whereType<GoRoute>().first;

      final redirectFn = guardedRoute.redirect!;
      final result = await redirectFn(_FakeContext(), _FakeState());

      expect(result, '/not-allowed');
    },
  );

  test(
    'applies redirect from ChildRoute with guards in StatefulShellModuleRoute',
    () async {
      final module = _StatefulShellWithChildGuardModule();

      final routes = module.configureRoutes(topLevel: true);
      final shell = routes.whereType<StatefulShellRoute>().first;

      final route = shell.branches.first.routes.whereType<GoRoute>().first;
      final redirectFn = route.redirect!;
      final result = await redirectFn(_FakeContext(), _FakeState());

      expect(result, '/denied');
    },
  );

  test(
    'only first guard result is respected in ChildRoute inside StatefulShell',
    () async {
      final module = _StatefulShellWithMultipleGuardsModule();

      final routes = module.configureRoutes(topLevel: true);
      final shell = routes.whereType<StatefulShellRoute>().first;

      final route = shell.branches.first.routes.whereType<GoRoute>().first;
      final redirectFn = route.redirect!;
      final result = await redirectFn(_FakeContext(), _FakeState());

      expect(result, '/first');
    },
  );

  test(
    'StatefulShellModuleRoute applies guard when ModuleRoute path is "/"',
    () async {
      final module = _StatefulShellGuardedModule();

      final routes = module.configureRoutes(topLevel: true);
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedRoute =
          shell.branches.first.routes.whereType<GoRoute>().first;
      final result = await guardedRoute.redirect!(_FakeContext(), _FakeState());

      expect(result, '/not-allowed');
    },
  );

  test('composePath joins base and sub correctly and cleans slashes', () {
    final wrapper = StatefulShellModuleRoute(
      routes: [],
      builder: (_, __, ___) => const Placeholder(),
    );

    expect(wrapper.composePath('/', 'profile'), '/profile');
    expect(wrapper.composePath('/settings/', '/profile/'), '/settings/profile');
    expect(wrapper.composePath('', ''), '/');
    expect(wrapper.composePath('a/', '/b'), '/a/b');
  });

  test(
    'isRootRouteForModule returns true for matching ModuleRoute root GoRoute',
    () {
      Widget dummyBuilder(BuildContext _, GoRouterState __) =>
          const Placeholder();

      final route = ModuleRoute('/home', module: _DummyModule());
      final wrapper = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
      );

      final configuredRoutes = [
        GoRoute(path: '/home', builder: dummyBuilder),
        GoRoute(path: '/home/extra', builder: dummyBuilder),
      ];

      bool result(RouteBase base) =>
          wrapper.isRootRouteForModule(base, route, configuredRoutes);

      expect(result(GoRoute(path: '/', builder: dummyBuilder)), isFalse);
      expect(result(GoRoute(path: '/home', builder: dummyBuilder)), isTrue);
      expect(result(GoRoute(path: '/other', builder: dummyBuilder)), isFalse);
    },
  );

  test('should be equal even if guards differ in ModuleRoute', () {
    builder(_, __, ___) => const Placeholder();
    final sharedModule = _DummyModule();

    final baseRoute = ModuleRoute('/home', module: sharedModule);

    final a = StatefulShellModuleRoute(builder: builder, routes: [baseRoute]);

    final b = StatefulShellModuleRoute(
      builder: builder,
      routes: [
        ModuleRoute('/home', module: sharedModule, guards: [_BlockGuard()]),
      ],
    );

    expect(a, equals(b));
  });

  test(
    'StatefulShellModuleRoute applies guard when ModuleRoute path is not "/"',
    () async {
      final module = _StatefulShellGuardedModuleWithRealPath();

      final routes = module.configureRoutes(topLevel: true);
      final shell = routes.whereType<StatefulShellRoute>().first;

      final guardedRoute = shell.branches.first.routes
          .whereType<GoRoute>()
          .firstWhere(
            (_) => true,
            orElse: () => throw TestFailure('No GoRoute found in first branch'),
          );

      final result = await guardedRoute.redirect!(_FakeContext(), _FakeState());

      expect(result, '/not-allowed');
    },
  );

  group('StatefulShellModuleRoute with RoutePatternModel', () {
    test('matches correct path and extracts parameters', () {
      final route = StatefulShellModuleRoute(
        routes: [ModuleRoute('/home', module: _DummyModule())],
        builder: (_, __, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(
          r'^/org/(\w+)/tab/home$',
          paramNames: ['orgId'],
        ),
      );

      final pattern = route.routePattern!;
      expect(pattern.regex.hasMatch('/org/acme/tab/home'), isTrue);

      final params = pattern.extractParams('/org/acme/tab/home');
      expect(params, equals({'orgId': 'acme'}));
    });

    test('returns false when path does not match pattern', () {
      final route = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(
          r'^/dashboard/(\w+)$',
          paramNames: ['section'],
        ),
      );

      final match = route.routePattern!.regex.hasMatch('/invalid/path');
      expect(match, isFalse);

      final params = route.routePattern!.extractParams('/invalid/path');
      expect(params, isEmpty);
    });

    test('== returns true when routePattern and all fields match', () {
      builder(_, __, ___) => const Placeholder();
      final pattern = RoutePatternModel.from(r'^/shell$', paramNames: []);

      final routeA = StatefulShellModuleRoute(
        routes: [],
        builder: builder,
        routePattern: pattern,
      );

      final routeB = StatefulShellModuleRoute(
        routes: [],
        builder: builder,
        routePattern: pattern,
      );
      expect(routeA, equals(routeB));
      expect(routeA.hashCode, equals(routeB.hashCode));
    });

    test('== returns false when routePatterns differ', () {
      final routeA = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(r'^/a$', paramNames: []),
      );
      final routeB = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(r'^/b$', paramNames: []),
      );

      expect(routeA, isNot(equals(routeB)));
    });
  });
}

final class _UnsupportedRoute implements IModule {}

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
  List<IModule> get routes => [
    ChildRoute('/', child: (_, __) => const Text('Profile')),
  ];
}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/home', child: (_, __) => const Placeholder()),
  ];
}

final class _GuardedChildModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/', child: (_, __) => const Placeholder()),
  ];
}

final class _GuardedChildModuleWithRealPath extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/guarded', child: (_, __) => const Placeholder()),
  ];
}

final class _ModuleWithGuardedChild extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      '/',
      child: (_, __) => const Placeholder(),
      guards: [_ChildBlockGuard()],
    ),
  ];
}

final class _ModuleWithMultipleGuards extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      '/',
      child: (_, __) => const Placeholder(),
      guards: [_GuardA(), _GuardB()],
    ),
  ];
}

final class _StatefulShellWithChildGuardModule extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [ModuleRoute('/home', module: _ModuleWithGuardedChild())],
    ),
  ];
}

final class _StatefulShellWithMultipleGuardsModule extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [ModuleRoute('/home', module: _ModuleWithMultipleGuards())],
    ),
  ];
}

final class _StatefulShellGuardedModule extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [
        ModuleRoute(
          '/home',
          module: _GuardedChildModule(),
          guards: [_BlockGuard()],
        ),
        ModuleRoute('/profile', module: _SimpleModule()),
      ],
    ),
  ];
}

final class _StatefulShellGuardedModuleWithRealPath extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [
        ModuleRoute(
          '/guarded',
          module: _GuardedChildModuleWithRealPath(),
          guards: [_BlockGuard()],
        ),
      ],
    ),
  ];
}

final class _FakeContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeState extends GoRouterState {
  _FakeState()
    : super(
        RouteConfiguration(
          ValueNotifier(RoutingConfig(routes: [])),
          navigatorKey: GlobalKey<NavigatorState>(),
        ),
        fullPath: '/',
        uri: Uri.parse('/'),
        matchedLocation: '/',
        pathParameters: const {},
        pageKey: const ValueKey('fake'),
      );
}
