import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/managers/injector_manager.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

void main() {
  test('Register root module simple', () async {
    final module = _ModuleMock(persistent: false);
    final manager = InjectorManager();

    manager.module = module;

    expect(manager.module, module);
  });

  test('Singleton behavior', () {
    final instance1 = InjectorManager();
    final instance2 = InjectorManager();

    expect(instance1, same(instance2));
  });

  // test('Register root module and binds', () async {
  //   final manager = InjectorManager();
  //   final module = _ModuleMock(persistent: false);

  //   await manager.registerBindsAppModule(module);

  //   expect(manager.module, module);
  //   expect(manager.isModuleActive(module), true);
  //   expect(manager.getActiveRoutesFor(module), isEmpty);
  // });

  test('Register binds if needed avoids duplicates', () async {
    final manager = InjectorManager();
    final module = _ModuleMock(persistent: false);

    await manager.registerBindsAppModule(module);
    await manager.registerBindsIfNeeded(module);

    final activeRoutes = manager.getActiveRoutesFor(module);
    expect(activeRoutes, isEmpty);
  });

  // test(
  //   'Route registration and unregistration triggers bind disposal',
  //   () async {
  //     final manager = InjectorManager();
  //     final module = _ModuleMock(persistent: false);

  //     await manager.registerBindsAppModule(module);
  //     manager.registerRoute('/home', module);

  //     expect(
  //       manager.getActiveRoutesFor(module).any((r) => r.path == '/home'),
  //       true,
  //     );

  //     manager.unregisterRoute('/home', module);

  //     await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

  //     expect(manager.isModuleActive(module), false);
  //   },
  // );

  test('Bind reference count increments and decrements correctly', () async {
    final typeB = int;
    final typeA = String;
    final manager = InjectorManager();

    manager.incrementBindReference(typeA);
    manager.incrementBindReference(typeA);
    manager.incrementBindReference(typeB);

    expect(manager.bindReferences[typeA], 2);
    expect(manager.bindReferences[typeB], 1);

    manager.decrementBindReference(typeA);
    expect(manager.bindReferences[typeA], 1);

    manager.decrementBindReference(typeA);
    expect(manager.bindReferences.containsKey(typeA), false);

    manager.decrementBindReference(typeB);
    expect(manager.bindReferences.containsKey(typeB), false);
  });

  test(
    'Unregister binds disposes only if no active routes and not persistent',
    () async {
      final manager = InjectorManager();
      final persistentModule = _ModuleMock(persistent: true);
      final nonPersistentModule = _ModuleMock(persistent: false);

      await manager.registerBindsAppModule(nonPersistentModule);
      manager.registerRoute('/test', nonPersistentModule);

      manager.unregisterRoute('/test', nonPersistentModule);

      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 50));

      expect(manager.isModuleActive(nonPersistentModule), false);

      await manager.registerBindsAppModule(persistentModule);
      manager.registerRoute('/persist', persistentModule);
      manager.unregisterRoute('/persist', persistentModule);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 50));

      expect(manager.isModuleActive(persistentModule), true);
    },
  );

  test('QueueManager serializes async bind registration', () async {
    int counter = 0;

    final manager = InjectorManager();
    final module1 = _ModuleMock(persistent: false);
    final module2 = _ModuleMock(persistent: false);

    Future<void> delayedBind(InjectorManager mgr, Module mod) async {
      await mgr.registerBindsIfNeeded(mod);
      counter++;
    }

    await Future.wait([
      delayedBind(manager, module1),
      delayedBind(manager, module2),
    ]);

    expect(counter, 2);
  });
}

final class _ModuleMock extends Module {
  final bool _persistent;

  _ModuleMock({required bool persistent}) : _persistent = persistent;

  @override
  List<Module> imports() => [];

  @override
  void binds(IInjector injector) {}

  @override
  bool get persistent => _persistent;
}
