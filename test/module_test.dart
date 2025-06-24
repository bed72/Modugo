import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

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
      expect(child.path, '/top/home');
    });

    test('configureRoutes returns all route types', () {
      final module = _ModuleWithStatefulShell();
      final routes = module.configureRoutes(topLevel: true, path: '/');

      expect(routes.any((r) => r is StatefulShellRoute), isTrue);
    });
  });
}

final class _ModuleInterface implements IModule {}

final class _Service {
  int value = 0;
}

final class _InnerModule extends Module {
  @override
  void binds(IInjector i) {
    i.addFactory<_Service>((_) => _Service());
  }

  @override
  List<IModule> get routes => [
    ChildRoute('/home', name: 'home', child: (_, __) => const Text('Home')),
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
      'with-branch',
      name: 'with-branch-route',
      child: (_, __) => const Placeholder(),
    ),
  ];
}

final class _RootModule extends Module {
  @override
  List<Module> get imports => [_InnerModule()];

  @override
  List<IModule> get routes => [
    ChildRoute(
      '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}

final class _ModuleWithDash extends Module {
  @override
  List<ChildRoute> get routes => [
    ChildRoute('/', name: 'root', child: (_, __) => const Placeholder()),
  ];
}

final class _ModuleWithSettings extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/', name: 'settings', child: (_, __) => const Placeholder()),
  ];
}

final class _ModuleWithStatefulShell extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (ctx, state, shell) => const Placeholder(),
      routes: [
        ModuleRoute('/', module: _ModuleWithDash()),
        ModuleRoute('/settings', module: _ModuleWithSettings()),
      ],
    ),
  ];
}

final class _ModuleWithOnExitFalse extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      '/some',
      name: 'on-exit-false',
      child: (_, __) => const Text('Some'),
      onExit: (_, __) async => false,
    ),
  ];
}

final class _ModuleWithShell extends Module {
  @override
  List<IModule> get routes => [
    ShellModuleRoute(
      binds: [(i) => i.addSingleton<_Service>((_) => _Service())],
      builder: (_, __, child) => Container(child: child),
      routes: [ChildRoute('tab1', child: (_, __) => const Placeholder())],
    ),
  ];
}

final class _ModuleWithNoRootChild extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('non-root', child: (_, __) => const Placeholder()),
  ];
}

final class _ParentModuleWithModuleRoute extends Module {
  final Module child;
  _ParentModuleWithModuleRoute({required this.child});

  @override
  List<IModule> get routes => [ModuleRoute('/child', module: child)];
}
