import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

import 'fakes/fakes.dart';

void main() {
  late final IManager manager;
  late final _RootModule rootModule;
  late final _InnerModule innerModule;

  setUp(() {
    final manager = Manager();
    manager.bindReferences.clear();
    manager.module = null;
    Injector().clearAll();
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
      final manager = Manager();

      final rootModule = _EmptyModule();
      final innerModule = _InnerModule();

      manager.registerBindsAppModule(rootModule);
      manager.registerBindsIfNeeded(innerModule);

      Injector().get<_Service>();

      expect(manager.isModuleActive(innerModule), isTrue);

      manager.registerRoute('/inner', innerModule);
      manager.unregisterRoute('/inner', innerModule);

      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(innerModule), isFalse);
      expect(manager.bindReferences.containsKey(_Service), isFalse);
    });

    test('should not register binds again for active module', () {
      manager.registerBindsIfNeeded(innerModule);

      final before = manager.bindReferences.length;
      manager.registerBindsIfNeeded(innerModule);

      expect(manager.bindReferences.length, equals(before));
    });

    test('manual unregisterBinds removes exclusive bind', () async {
      final manager = Manager();
      final rootModule = _EmptyModule();
      final innerModule = _InnerModule();

      manager.registerBindsAppModule(rootModule);
      manager.registerBindsIfNeeded(innerModule);

      Injector().get<_Service>();
      manager.unregisterBinds(innerModule);

      expect(manager.isModuleActive(innerModule), isFalse);
      expect(() => Injector().get<_Service>(), throwsException);
    });

    test('Injector clearAll removes all binds', () async {
      manager.registerBindsIfNeeded(innerModule);
      manager.registerBindsIfNeeded(rootModule);

      Injector().clearAll();
      expect(() => Injector().get<_Service>(), throwsException);
    });

    test('should throw on cyclic dependencies at resolution', () {
      final module = _CyclicModule();
      manager.registerBindsIfNeeded(module);

      expect(() => Injector().get<_CyclicA>(), throwsA(isA<Error>()));
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

  test('module getter and setter work as expected', () {
    final manager = Manager();
    final module = _RootModule();

    manager.module = module;
    expect(manager.module, same(module));
  });

  test(
    'shared bind across modules is not disposed until all are inactive',
    () async {
      final manager = Manager();
      final sharedModule = _InnerModule();

      final moduleA = _ImportAnotherModule();
      final moduleB = _ImportAnotherModule();

      manager.registerBindsIfNeeded(sharedModule);
      manager.registerBindsIfNeeded(moduleA);
      manager.registerBindsIfNeeded(moduleB);

      manager.registerRoute('/a', moduleA);
      manager.registerRoute('/b', moduleB);

      manager.unregisterRoute('/a', moduleA);
      manager.unregisterRoute('/b', moduleB);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 100));

      expect(manager.bindReferences.containsKey(_Service), isTrue);

      manager.unregisterRoute('/shared', sharedModule);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 100));

      expect(manager.bindReferences.containsKey(_Service), isFalse);
    },
  );

  group('Persistent module', () {
    test('should not unregister persistent module binds', () async {
      final module = _PersistentModule();
      manager.registerBindsIfNeeded(module);

      expect(module.wasRegistered, isTrue);
      expect(Modugo.get<String>(), equals('persistent'));

      manager.unregisterRoute('/home', module);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(() => Modugo.get<String>(), returnsNormally);
    });

    test('should unregister normal module binds after delay', () async {
      final module = _DisposableModule();
      manager.registerBindsIfNeeded(module);

      expect(module.wasRegistered, isTrue);
      expect(Modugo.get<int>(), equals(42));

      manager.unregisterRoute('/path', module);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(() => Modugo.get<int>(), throwsA(isA<Exception>()));
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
  List<Module> get imports => [_InnerModule()];
}

final class _InnerModule extends Module {
  @override
  void binds(IInjector i) {
    i.addFactory<_Service>((_) => _Service());
  }
}

final class _PersistentModule extends Module {
  @override
  bool get persistent => true;

  bool wasRegistered = false;

  @override
  void binds(IInjector i) {
    wasRegistered = true;
    i.addSingleton<String>((_) => 'persistent');
  }
}

final class _DisposableModule extends Module {
  bool wasRegistered = false;

  @override
  void binds(IInjector i) {
    wasRegistered = true;
    i.addSingleton<int>((_) => 42);
  }
}

final class _CyclicModule extends Module {
  @override
  void binds(IInjector i) {
    i
      ..addFactory<_CyclicA>((i) => _CyclicA(i.get<_CyclicB>()))
      ..addFactory<_CyclicB>((i) => _CyclicB(i.get<_CyclicA>()));
  }
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
