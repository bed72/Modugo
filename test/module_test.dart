import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/registers/binder_registry.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import 'fakes/fakes.dart';

void main() {
  group('Module route configuration', () {
    test(
      'throws error for unsupported route type in StatefulShellModuleRoute',
      () {
        expect(() {
          StatefulShellModuleRoute(
            builder: (_, _, _) => const Placeholder(),
            routes: [_ModuleInterface()],
          ).toRoute(path: '');
        }, throwsA(isA<UnsupportedError>()));
      },
    );
  });

  group('Module edge cases', () {
    test('ModuleRoute with no "/" route does not throw', () async {
      final module = _ModuleWithNoRootChild();
      await startModugoFake(module: module);
      final parent = _ParentModuleWithModuleRoute(child: module);

      expect(() => parent.configureRoutes(), returnsNormally);
    });
  });

  group('Module route configuration', () {
    test('creates ChildRoutes and registers binds', () async {
      final module = _InnerModule();
      await startModugoFake(module: module);
      module.configureRoutes();

      expect(() => module.i.get<_ServiceMock>(), returnsNormally);
    });

    test('creates ModuleRoute using / as default child', () async {
      final module = _RootModule();
      await startModugoFake(module: module);
      final routes = module.configureRoutes();

      final profile = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/profile',
      );
      expect(profile.name, 'profile-root');
    });

    test('creates ShellRoute and registers shell binds', () async {
      final module = _ModuleWithShell();
      await startModugoFake(module: module);
      final routes = module.configureRoutes();

      expect(() => module.i.get<_ServiceMock>(), returnsNormally);
      expect(routes.whereType<ShellRoute>().isNotEmpty, isTrue);
    });

    test('creates StatefulShellRoute with branches', () async {
      final module = _ModuleWithStatefulShell();
      await startModugoFake(module: module);
      final routes = module.configureRoutes();

      final shell = routes.whereType<StatefulShellRoute>().first;
      expect(shell.branches.length, 2);
    });
  });

  group('Module bind lifecycle', () {
    test('registers binds before builder is called', () async {
      final module = _RootModule();
      await startModugoFake(module: module);
      final routes = module.configureRoutes();

      final goRoute = routes.whereType<GoRoute>().first;
      final widget = goRoute.builder!(BuildContextFake(), StateFake());

      expect(widget, isA<Widget>());
    });

    test('configureRoutes returns all route types', () {
      final module = _ModuleWithStatefulShell();
      final routes = module.configureRoutes();

      expect(routes.any((r) => r is StatefulShellRoute), isTrue);
    });
  });

  group('ModuleRoute - guards and redirect precedence', () {
    test('falls back to ModuleRoute.redirect if all redirect', () async {
      final module = _SimpleChildModule();

      final guardedRoute = ModuleRoute(
        module: module,
        path: '/guarded',
        redirect: (_, _) => '/fallback',
      );

      final parent = _CustomParentModule([guardedRoute]);

      final routes = parent.configureRoutes();
      final goRoute = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/guarded',
      );

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());
      expect(result, '/fallback');
    });

    test(
      'uses ChildRoute.redirect only if redirect and module.redirect allow',
      () async {
        final module = _SimpleChildModuleWithRedirect();
        final parent = _ParentModuleWithModuleRoute(child: module);

        final route = ModuleRoute(module: module, path: '/guarded');

        parent.routes().clear();
        parent.routes().add(route);

        final routes = parent.configureRoutes();
        final goRoute = routes.whereType<GoRoute>().first;

        final result = await goRoute.redirect!(BuildContextFake(), StateFake());
        expect(result, '/child-redirect');
      },
    );

    test('returns null if guards allow and no redirects are defined', () async {
      final module = _SimpleChildModule();
      final parent = _ParentModuleWithModuleRoute(child: module);

      final route = ModuleRoute(module: module, path: '/guarded');

      parent.routes().clear();
      parent.routes().add(route);

      final routes = parent.configureRoutes();
      final goRoute = routes.whereType<GoRoute>().first;

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());
      expect(result, isNull);
    });
  });

  test('Module.configureRoutes throws ArgumentError on invalid path', () {
    final module = _InvalidPathModule();

    expect(
      () => module.configureRoutes(),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Invalid path syntax'),
        ),
      ),
    );
  });
}

final class _ModuleInterface implements IRoute {}

final class _ServiceMock {
  int value = 0;
}

final class _InnerModule extends Module {
  @override
  void binds() {
    i.registerFactory<_ServiceMock>(_ServiceMock.new);
  }
}

final class _RootModule extends Module {
  @override
  List<BinderRegistry> imports() => [_InnerModule()];

  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}

final class _InvalidPathModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/product/:(id', child: (_, _) => const Placeholder()),
  ];
}

final class _ModuleWithDash extends Module {
  @override
  List<ChildRoute> routes() => [
    ChildRoute(path: '/', name: 'root', child: (_, _) => const Placeholder()),
  ];
}

final class _ModuleWithSettings extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      name: 'settings',
      child: (_, _) => const Placeholder(),
    ),
  ];
}

final class _ModuleWithStatefulShell extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (ctx, state, shell) => const Placeholder(),
      routes: [
        ModuleRoute(path: '/', module: _ModuleWithDash()),
        ModuleRoute(path: '/settings', module: _ModuleWithSettings()),
      ],
    ),
  ];
}

final class _ModuleWithShell extends Module {
  @override
  List<IRoute> routes() => [
    ShellModuleRoute(
      builder: (_, _, child) => Container(child: child),
      routes: [ChildRoute(path: 'tab1', child: (_, _) => const Placeholder())],
    ),
  ];
}

final class _ModuleWithNoRootChild extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: 'non-root', child: (_, _) => const Placeholder()),
  ];
}

final class _ParentModuleWithModuleRoute extends Module {
  final Module child;
  _ParentModuleWithModuleRoute({required this.child});

  @override
  List<IRoute> routes() => [ModuleRoute(path: '/child', module: child)];
}

final class _CustomParentModule extends Module {
  final List<IRoute> customRoutes;

  _CustomParentModule(this.customRoutes);

  @override
  List<IRoute> routes() => customRoutes;
}

final class _SimpleChildModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Text('Page')),
  ];
}

final class _SimpleChildModuleWithRedirect extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      child: (_, _) => const Text('Page'),
      redirect: (_, _) => '/child-redirect',
    ),
  ];
}
