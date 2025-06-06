import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/services_mock.dart';
import 'mocks/modules_mock.dart';

void main() {
  late final ManagerInterface manager;
  late final RootModuleMock rootModule;
  late final InnerModuleMock innerModule;

  setUpAll(() async {
    manager = Manager();
    rootModule = RootModuleMock();
    innerModule = rootModule.imports.first as InnerModuleMock;

    await startModugoMock(module: rootModule);
  });

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
    'should not dispose shared bind until all modules are removed',
    () async {
      final anotherModule = AnotherModuleMock();

      manager.registerBindsIfNeeded(innerModule);
      manager.registerBindsIfNeeded(anotherModule);

      expect(manager.isModuleActive(innerModule), isTrue);
      expect(manager.isModuleActive(anotherModule), isTrue);

      manager.unregisterRoute('/inner', innerModule);
      await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

      expect(manager.isModuleActive(anotherModule), isTrue);
      expect(manager.isModuleActive(innerModule), isFalse);
    },
  );

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

  test('should not register binds again for active module', () {
    manager.registerBindsIfNeeded(innerModule);

    final before = manager.bindReferences.length;
    manager.registerBindsIfNeeded(innerModule);

    expect(manager.bindReferences.length, equals(before));
  });

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

  test('bind reference count should decrease correctly', () async {
    manager.registerBindsIfNeeded(innerModule);

    final type = innerModule.binds.first.instance.runtimeType;
    print('Captured type after register: $type');

    expect(manager.isModuleActive(innerModule), isTrue);

    manager.registerRoute('/inner', innerModule);
    manager.unregisterRoute('/inner', innerModule);
    await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

    expect(manager.isModuleActive(innerModule), isFalse);
    expect(manager.bindReferences.containsKey(type), isFalse);
  });

  test('manual unregisterBinds works', () {
    manager.registerBindsIfNeeded(innerModule);
    manager.unregisterBinds(innerModule);

    expect(manager.isModuleActive(innerModule), isFalse);
    expect(() => Bind.get<OtherServiceMock>(), throwsException);
  });

  test('Injector clearAll removes all binds', () {
    manager.registerBindsIfNeeded(innerModule);
    manager.registerBindsIfNeeded(rootModule);

    Bind.clearAll();

    expect(() => Bind.get<OtherServiceMock>(), throwsException);
  });

  test('should throw on cyclic dependencies at resolution', () {
    final cyclicModule = CyclicModuleMock();

    manager.registerBindsIfNeeded(cyclicModule);

    expect(() => Bind.get<CyclicMock>(), throwsA(isA<Error>()));
  });

  test('isModuleActive returns true when module is active', () {
    manager.registerBindsIfNeeded(innerModule);

    expect(manager.isModuleActive(innerModule), isTrue);
  });

  test('isModuleActive returns false when module is not active', () {
    final inactiveModule = AnotherModuleMock();

    expect(manager.isModuleActive(inactiveModule), isFalse);
  });
}
