import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

import 'mocks/modugo_mock.dart';
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

  test('bind reference count should decrease correctly', () async {
    final type = innerModule.binds.first.instance.runtimeType;

    manager.registerBindsIfNeeded(innerModule);
    expect(manager.bindReferences[type], greaterThan(0));

    manager.unregisterRoute('/inner', innerModule);
    await Future.delayed(Duration(milliseconds: disposeMilisenconds + 72));

    expect(
      manager.bindReferences.containsKey(type),
      isTrue,
    ); // Because is a root module
  });

  test('should not register binds again for active module', () {
    manager.registerBindsIfNeeded(innerModule);

    final before = manager.bindReferences.length;
    manager.registerBindsIfNeeded(innerModule);

    expect(manager.bindReferences.length, equals(before));
  });
}
