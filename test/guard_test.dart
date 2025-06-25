import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

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

  group('Module route configuration guard', () {
    test('creates ShellRoute and registers using guard', () async {
      final module = _ModuleWithShell();
      await startModugoFake(module: module);
      final routes = module.configureRoutes(topLevel: true);

      expect(routes.whereType<ShellRoute>().isNotEmpty, isTrue);
      expect(() => Injector().get<_Service>(), returnsNormally);
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
    ChildRoute(
      '/home',
      name: 'home',
      child: (_, __) => const Text('Home'),
      guards: [FakeGuard()],
    ),
  ];
}

class FakeGuard implements IGuard {
  @override
  Future<bool> canActivate(String routeName) async {
    if (routeName == 'route') {
      return false; // Simulate a guard that blocks navigation
    }

    return true;
  }
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
      routes: [
        ChildRoute(
          'tab1',
          child: (_, __) => const Placeholder(),
          guards: [FakeGuard()],
        ),
      ],
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
