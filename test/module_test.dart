import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/modugo.dart';

import 'fakes/fakes.dart';

void main() {
  setUp(() async {
    Injector().clearAll();
    final manager = Manager();
    manager.module = null;
    manager.bindReferences.clear();
  });

  group('Module route configuration', () {
    test(
      'throws error for unsupported route type in StatefulShellModuleRoute',
      () {
        expect(() {
          StatefulShellModuleRoute(
            builder: (ctx, state, shell) => const Placeholder(),
            routes: [_ModuleInterface()],
          ).toRoute(topLevel: true, path: '');
        }, throwsA(isA<UnsupportedError>()));
      },
    );
  });

  group('Module edge cases', () {
    test('ModuleRoute with no "/" route does not throw', () async {
      final module = _ModuleWithNoRootChild();
      await startModugoFake(module: module);
      final parent = _ParentModuleWithModuleRoute(child: module);

      expect(() => parent.configureRoutes(topLevel: true), returnsNormally);
    });
  });

  group('Module route configuration', () {
    test('creates ChildRoutes and registers binds', () async {
      final module = _InnerModule();
      await startModugoFake(module: module);
      module.configureRoutes(topLevel: true, path: '/home');

      expect(() => Injector().get<_Service>(), returnsNormally);
    });

    test('creates ModuleRoute using / as default child', () async {
      final module = _RootModule();
      await startModugoFake(module: module);
      final routes = module.configureRoutes(topLevel: true);

      final profile = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/profile',
      );
      expect(profile.name, 'profile-root');
    });

    test('creates ShellRoute and registers shell binds', () async {
      final module = _ModuleWithShell();
      await startModugoFake(module: module);
      final routes = module.configureRoutes(topLevel: true);

      expect(routes.whereType<ShellRoute>().isNotEmpty, isTrue);
      expect(() => Injector().get<_Service>(), returnsNormally);
    });

    test('creates StatefulShellRoute with branches', () async {
      final module = _ModuleWithStatefulShell();
      await startModugoFake(module: module);
      final routes = module.configureRoutes(topLevel: true);

      final shell = routes.whereType<StatefulShellRoute>().first;
      expect(shell.branches.length, 2);
    });
  });

  group('Module bind lifecycle', () {
    test('registers binds before builder is called', () async {
      final module = _RootModule();
      await startModugoFake(module: module);
      final routes = module.configureRoutes(topLevel: true);

      final goRoute = routes.whereType<GoRoute>().first;
      final widget = goRoute.builder!(BuildContextFake(), StateFake());

      expect(widget, isA<Widget>());
    });

    test('does not unregister if onExit returns false', () async {
      final module = _ModuleWithOnExitFalse();
      await startModugoFake(module: module);
      module.configureRoutes(topLevel: true);

      final goRoute =
          module
                  .configureRoutes(topLevel: true)
                  .firstWhere((r) => r is GoRoute && r.name == 'on-exit-false')
              as GoRoute;

      final result = await goRoute.onExit?.call(
        BuildContextFake(),
        StateFake(),
      );
      expect(result, isFalse);

      final manager = Manager();
      expect(manager.isModuleActive(module), isTrue);
    });

    test('unregisters module after route exit', () async {
      final module = _ModuleWithBranch();
      await startModugoFake(module: module);

      final manager = Manager();
      manager.registerBindsIfNeeded(module);
      manager.registerRoute('/with-branch', module, branch: 'branch-a');

      expect(manager.isModuleActive(module), isTrue);

      manager.unregisterRoute('/with-branch', module, branch: 'branch-a');
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(module), isFalse);
    });

    test('ChildRoute path is composed correctly with topLevel', () async {
      final module = _InnerModule();
      final routes = module.configureRoutes(topLevel: true, path: '/top');

      final child = routes.whereType<GoRoute>().first;
      expect(child.path, '/home');
    });

    test('configureRoutes returns all route types', () {
      final module = _ModuleWithStatefulShell();
      final routes = module.configureRoutes(topLevel: true, path: '/');

      expect(routes.any((r) => r is StatefulShellRoute), isTrue);
    });
  });

  group('ModuleRoute - guards and redirect precedence', () {
    test('redirects immediately if any guard blocks', () async {
      final module = _SimpleChildModule();
      final guardedRoute = ModuleRoute(
        module: module,
        path: '/guarded',
        guards: [_GuardAllow(), _GuardBlock('/denied')],
      );

      final parent = _CustomParentModule([guardedRoute]);

      final routes = parent.configureRoutes(topLevel: true);
      final goRoute = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/guarded',
      );

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());
      expect(result, '/denied');
    });

    test('falls back to ModuleRoute.redirect if all guards allow', () async {
      final module = _SimpleChildModule();

      final guardedRoute = ModuleRoute(
        module: module,
        path: '/guarded',
        guards: [_GuardAllow()],
        redirect: (_, _) => '/fallback',
      );

      final parent = _CustomParentModule([guardedRoute]);

      final routes = parent.configureRoutes(topLevel: true);
      final goRoute = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/guarded',
      );

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());
      expect(result, '/fallback');
    });

    test(
      'uses ChildRoute.redirect only if guards and module.redirect allow',
      () async {
        final module = _SimpleChildModuleWithRedirect();
        final parent = _ParentModuleWithModuleRoute(child: module);

        final route = ModuleRoute(
          module: module,
          path: '/guarded',
          guards: [_GuardAllow()],
        );

        parent.routes.clear();
        parent.routes.add(route);

        final routes = parent.configureRoutes(topLevel: true);
        final goRoute = routes.whereType<GoRoute>().first;

        final result = await goRoute.redirect!(BuildContextFake(), StateFake());
        expect(result, '/child-redirect');
      },
    );

    test('returns null if guards allow and no redirects are defined', () async {
      final module = _SimpleChildModule();
      final parent = _ParentModuleWithModuleRoute(child: module);

      final route = ModuleRoute(
        module: module,
        path: '/guarded',
        guards: [_GuardAllow()],
      );

      parent.routes.clear();
      parent.routes.add(route);

      final routes = parent.configureRoutes(topLevel: true);
      final goRoute = routes.whereType<GoRoute>().first;

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());
      expect(result, isNull);
    });
  });

  group('Modugo.matchRoute', () {
    setUp(() {
      Modugo.manager.module = null;
    });

    test('returns null if no route matches', () {
      final root = _EmptyModule();
      Modugo.manager.module = root;

      final result = Modugo.matchRoute('/non-existent');
      expect(result, isNull);
    });

    test('matches ChildRoute with routePattern', () {
      final route = ChildRoute(
        path: '/user/:id',
        routePattern: RoutePatternModel.from(
          r'^/user/(\d+)$',
          paramNames: ['id'],
        ),
        child: (_, _) => const Placeholder(),
      );

      final root = _ModuleWith([route]);
      Modugo.manager.module = root;

      final result = Modugo.matchRoute('/user/42');
      expect(result, isNotNull);
      expect(result!.params['id'], '42');
      expect(result.route, equals(route));
    });

    test('matches ModuleRoute with routePattern', () {
      final nested = _ModuleWith([]);
      final route = ModuleRoute(
        module: nested,
        path: '/profile',
        routePattern: RoutePatternModel.from(r'^/profile$', paramNames: []),
      );

      final root = _ModuleWith([route]);
      Modugo.manager.module = root;

      final result = Modugo.matchRoute('/profile');
      expect(result, isNotNull);
      expect(result!.route, equals(route));
    });

    test('matches ShellModuleRoute with routePattern', () {
      final shell = ShellModuleRoute(
        routes: [],
        builder: (_, _, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(r'^/shell$', paramNames: []),
      );

      final root = _ModuleWith([shell]);
      Modugo.manager.module = root;

      final result = Modugo.matchRoute('/shell');
      expect(result, isNotNull);
      expect(result!.route, equals(shell));
    });

    test('matches StatefulShellModuleRoute with routePattern', () {
      final shell = StatefulShellModuleRoute(
        routes: [],
        builder: (_, _, ___) => const Placeholder(),
        routePattern: RoutePatternModel.from(
          r'^/tabs/(home|settings)$',
          paramNames: ['tab'],
        ),
      );

      final root = _ModuleWith([shell]);
      Modugo.manager.module = root;

      final result = Modugo.matchRoute('/tabs/home');
      expect(result, isNotNull);
      expect(result!.params['tab'], 'home');
      expect(result.route, equals(shell));
    });
  });
}

final class _ModuleInterface implements IModule {}

final class _Service {
  int value = 0;
}

final class _EmptyModule extends Module {
  @override
  List<IModule> get routes => [];
}

final class _ModuleWith extends Module {
  final List<IModule> _routes;
  _ModuleWith(this._routes);

  @override
  List<IModule> get routes => _routes;
}

final class _InnerModule extends Module {
  @override
  void binds(IInjector i) {
    i.addFactory<_Service>((_) => _Service());
  }

  @override
  List<IModule> get routes => [
    ChildRoute(
      name: 'home',
      path: '/home',
      child: (_, _) => const Text('Home'),
    ),
  ];
}

final class _ModuleWithBranch extends Module {
  @override
  void binds(IInjector i) {
    i.addSingleton<_Service>((_) => _Service());
  }

  @override
  List<IModule> get routes => [
    ChildRoute(
      path: 'with-branch',
      name: 'with-branch-route',
      child: (_, _) => const Placeholder(),
    ),
  ];
}

final class _RootModule extends Module {
  @override
  List<Module> get imports => [_InnerModule()];

  @override
  List<IModule> get routes => [
    ChildRoute(
      path: '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}

final class _ModuleWithDash extends Module {
  @override
  List<ChildRoute> get routes => [
    ChildRoute(path: '/', name: 'root', child: (_, _) => const Placeholder()),
  ];
}

final class _ModuleWithSettings extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      path: '/',
      name: 'settings',
      child: (_, _) => const Placeholder(),
    ),
  ];
}

final class _ModuleWithStatefulShell extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (ctx, state, shell) => const Placeholder(),
      routes: [
        ModuleRoute(path: '/', module: _ModuleWithDash()),
        ModuleRoute(path: '/settings', module: _ModuleWithSettings()),
      ],
    ),
  ];
}

final class _ModuleWithOnExitFalse extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      path: '/some',
      name: 'on-exit-false',
      onExit: (_, _) async => false,
      child: (_, _) => const Text('Some'),
    ),
  ];
}

final class _ModuleWithShell extends Module {
  @override
  List<IModule> get routes => [
    ShellModuleRoute(
      binds: [(i) => i.addSingleton<_Service>((_) => _Service())],
      builder: (_, _, child) => Container(child: child),
      routes: [ChildRoute(path: 'tab1', child: (_, _) => const Placeholder())],
    ),
  ];
}

final class _ModuleWithNoRootChild extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(path: 'non-root', child: (_, _) => const Placeholder()),
  ];
}

final class _ParentModuleWithModuleRoute extends Module {
  final Module child;
  _ParentModuleWithModuleRoute({required this.child});

  @override
  List<IModule> get routes => [ModuleRoute(path: '/child', module: child)];
}

final class _CustomParentModule extends Module {
  final List<IModule> customRoutes;

  _CustomParentModule(this.customRoutes);

  @override
  List<IModule> get routes => customRoutes;
}

final class _SimpleChildModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(path: '/', child: (_, _) => const Text('Page')),
  ];
}

final class _SimpleChildModuleWithRedirect extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      path: '/',
      child: (_, _) => const Text('Page'),
      redirect: (_, _) => '/child-redirect',
    ),
  ];
}

final class _GuardAllow implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}

final class _GuardBlock implements IGuard {
  final String path;
  _GuardBlock(this.path);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => path;
}
