import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

import 'fakes/fakes.dart';

void main() {
  late final _RootModule rootModule;
  late final _InnerModule innerModule;
  late final ManagerInterface manager;

  setUp(() {
    final manager = Manager();
    manager.bindReferences.clear();
    manager.module = null;
    Bind.clearAll();
  });

  setUpAll(() async {
    manager = Manager();
    rootModule = _RootModule();
    innerModule = rootModule.imports.first as _InnerModule;

    await startModugoFake(module: rootModule);
  });

  group('Module activity and lifecycle', () {
    test('should unregister binds of inner module properly', () async {
      manager.registerBindsIfNeeded(innerModule);
      expect(manager.isModuleActive(innerModule), isTrue);

      manager.registerRoute('/inner', innerModule);
      manager.unregisterRoute('/inner', innerModule);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(rootModule), isTrue);
      expect(manager.isModuleActive(innerModule), isFalse);
    });

    test(
      'should not dispose root module even if all routes are removed',
      () async {
        manager.registerBindsAppModule(rootModule);
        manager.registerRoute('/root', rootModule);
        manager.unregisterRoute('/root', rootModule);
        await Future.delayed(Duration(milliseconds: disposeMilisenconds + 50));

        expect(manager.isModuleActive(rootModule), isTrue);
      },
    );

    test('isModuleActive returns true when module is active', () {
      manager.registerBindsIfNeeded(innerModule);
      expect(manager.isModuleActive(innerModule), isTrue);
    });

    test('isModuleActive returns false when module is not active', () {
      final module = _ImportAnotherModule();
      expect(manager.isModuleActive(module), isFalse);
    });
  });

  group('Bind reference tracking', () {
    test('bind reference count should decrease correctly', () async {
      manager.registerBindsIfNeeded(innerModule);

      final type = innerModule.binds.first.instance.runtimeType;
      expect(manager.isModuleActive(innerModule), isTrue);

      manager.registerRoute('/inner', innerModule);
      manager.unregisterRoute('/inner', innerModule);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(innerModule), isFalse);
      expect(manager.bindReferences.containsKey(type), isFalse);
    });

    test('should not register binds again for active module', () {
      manager.registerBindsIfNeeded(innerModule);

      final before = manager.bindReferences.length;
      manager.registerBindsIfNeeded(innerModule);

      expect(manager.bindReferences.length, equals(before));
    });

    test('manual unregisterBinds removes exclusive bind', () async {
      manager.registerBindsIfNeeded(innerModule);
      manager.unregisterBinds(innerModule);

      expect(manager.isModuleActive(innerModule), isFalse);
      expect(() => Bind.get<_Service>(), throwsException);
    });

    test('Injector clearAll removes all binds', () async {
      manager.registerBindsIfNeeded(innerModule);
      manager.registerBindsIfNeeded(rootModule);

      Bind.clearAll();
      expect(() => Bind.get<_Service>(), throwsException);
    });

    test('should throw on cyclic dependencies at resolution', () {
      final module = _CyclicModule();
      manager.registerBindsIfNeeded(module);
      expect(() => Bind.get<_CyclicA>(), throwsA(isA<Error>()));
    });
  });

  group('Route registration and disposal', () {
    test(
      'should keep module active while at least one route is registered',
      () async {
        manager.registerBindsIfNeeded(innerModule);

        manager.registerRoute('/inner/1', innerModule);
        manager.registerRoute('/inner/2', innerModule);
        manager.unregisterRoute('/inner/1', innerModule);
        await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

        expect(manager.isModuleActive(innerModule), isTrue);

        manager.unregisterRoute('/inner/2', innerModule);
        await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

        expect(manager.isModuleActive(innerModule), isFalse);
      },
    );

    test(
      'should not dispose shared bind until all modules are removed',
      () async {
        final module = _ImportAnotherModule();

        manager.registerBindsIfNeeded(innerModule);
        manager.registerBindsIfNeeded(module);

        expect(manager.isModuleActive(innerModule), isTrue);
        expect(manager.isModuleActive(module), isTrue);

        manager.unregisterRoute('/inner', innerModule);
        await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

        expect(manager.isModuleActive(module), isTrue);
        expect(manager.isModuleActive(innerModule), isFalse);
      },
    );

    test(
      'unregisterRoute removes RouteAccessModel and disposes when empty',
      () async {
        final module = _ImportAnotherModule();
        final manager = Manager();

        manager.registerBindsIfNeeded(module);
        manager.registerRoute('/to-remove', module, branch: 'main');

        expect(manager.isModuleActive(module), isTrue);

        manager.unregisterRoute('/to-remove', module, branch: 'main');
        await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

        expect(manager.isModuleActive(module), isFalse);
      },
    );

    test('unregisterRoute does not dispose if other branches remain', () async {
      final module = _ImportAnotherModule();
      final manager = Manager();

      manager.registerBindsIfNeeded(module);
      manager.registerRoute('/cart', module, branch: 'a');
      manager.registerRoute('/cart', module, branch: 'b');

      manager.unregisterRoute('/cart', module, branch: 'a');
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(module), isTrue);

      manager.unregisterRoute('/cart', module, branch: 'b');
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(module), isFalse);
    });

    test(
      'calling unregisterRoute with no matching RouteAccessModel does nothing',
      () {
        final module = _ImportAnotherModule();
        final manager = Manager();

        manager.registerBindsIfNeeded(module);
        manager.registerRoute('/match', module, branch: 'x');

        manager.unregisterRoute('/wrong', module, branch: 'x');
        manager.unregisterRoute('/match', module, branch: 'y');

        expect(manager.isModuleActive(module), isTrue);

        manager.unregisterRoute('/match', module, branch: 'x');
      },
    );
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

final class _InnerModule extends Module {
  @override
  List<Bind> get binds => [Bind.factory<_Service>((_) => _Service())];
}

final class _ImportAnotherModule extends Module {
  @override
  List<Module> get imports => [_InnerModule()];
}

final class _CyclicModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.factory<_CyclicA>((i) => _CyclicA(i.get<_CyclicB>())),
    Bind.factory<_CyclicB>((i) => _CyclicB(i.get<_CyclicA>())),
  ];
}

final class _RootModule extends Module {
  @override
  List<Module> get imports => [_InnerModule()];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}
