import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

import 'fakes/fakes.dart';

void main() {
  late final IManager manager;
  late final _RootModule rootModule;
  late final _InnerModule innerModule;

  setUp(() {
    final manager = Manager();
    manager.module = null;
  });

  setUpAll(() async {
    manager = Manager();
    rootModule = _RootModule();
    innerModule = rootModule.imports().first as _InnerModule;

    await startModugoFake(module: rootModule);
  });

  group('Module activity and lifecycle', () {
    test(
      'should not dispose root module even if all routes are removed',
      () async {
        manager.registerRoute('/root', rootModule);
        manager.unregisterRoute('/root', rootModule);
        await Future.delayed(Duration(milliseconds: 50));

        expect(manager.isModuleActive(rootModule), isTrue);
      },
    );

    test('isModuleActive returns false when module is not active', () {
      final module = _ImportAnotherModule();
      expect(manager.isModuleActive(module), isFalse);
    });
  });

  group('Route registration and disposal', () {
    test(
      'should keep module active while at least one route is registered',
      () async {
        manager.registerRoute('/inner/1', innerModule);
        manager.registerRoute('/inner/2', innerModule);
        manager.unregisterRoute('/inner/1', innerModule);
        await Future.delayed(Duration(milliseconds: 72));

        expect(manager.isModuleActive(innerModule), isTrue);

        manager.unregisterRoute('/inner/2', innerModule);
        await Future.delayed(Duration(milliseconds: 72));

        expect(manager.isModuleActive(innerModule), isFalse);
      },
    );
  });

  test('module getter and setter work as expected', () {
    final manager = Manager();
    final module = _RootModule();

    manager.module = module;
    expect(manager.module, same(module));
  });

  group('Manager.rootModule', () {
    test('returns the module after being set', () {
      final manager = Manager();
      final module = _EmptyModule();

      manager.module = module;

      expect(manager.rootModule, equals(module));
    });

    test('throws if accessed before being set', () {
      final manager = Manager();
      manager.module = null;

      expect(() => manager.rootModule, throwsStateError);
    });
  });
}

final class _Service {
  int value = 0;
}

final class _CyclicA {
  final _CyclicB b;
  _CyclicA(this.b);
}

final class _CyclicB {
  final _CyclicA a;
  _CyclicB(this.a);
}

final class _EmptyModule extends Module {}

final class _ImportAnotherModule extends Module {
  @override
  List<Module> imports() => [_InnerModule()];
}

final class _InnerModule extends Module {
  @override
  void binds() {
    i.registerFactory<_Service>(() => _Service());
  }
}

final class _RootModule extends Module {
  @override
  List<Module> imports() => [_InnerModule()];

  @override
  List<IModule> routes() => [
    ChildRoute(
      path: '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}
