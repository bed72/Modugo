import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules/implementations_mock.dart';
import 'mocks/modules/multi_modules_mock.dart';

void main() {
  late final Manager manager;
  late final MultiModulesRootModuleMock rootModule;
  late final MultiModulesInnerModuleMock innerModule;

  setUpAll(() {
    manager = Manager();
    rootModule = MultiModulesRootModuleMock();
    innerModule = MultiModulesInnerModuleMock();

    manager.bindReferences.clear();
    Bind.clearAll();
  });

  test('Inner module resolves root module dependencies', () async {
    await startModugoMock(module: innerModule, debugLogDiagnostics: true);

    manager.registerBindsIfNeeded(innerModule);

    final cubit = Bind.get<ModulesCubitMock>();
    expect(cubit, isNotNull);
    expect(cubit.repository, isA<ModulesRepositoryMock>());

    final repository = Bind.get<ModulesRepositoryMock>();
    expect(repository, isNotNull);
    expect(repository is ModulesRepositoryMockImpl, isTrue);

    final client = Bind.get<ModulesClientMock>();
    expect(client, isNotNull);
    expect(client is ModulesClientMockImpl, isTrue);

    final repoImpl = cubit.repository as ModulesRepositoryMockImpl;
    final clientFromRepo = repoImpl.client;
    final clientFromContainer = Bind.get<ModulesClientMock>();
    expect(identical(clientFromRepo, clientFromContainer), isTrue);
  });

  test(
    'Unregister inner module cleans up all dependencies (The root module should not clear references)',
    () async {
      await startModugoMock(module: innerModule, debugLogDiagnostics: true);

      manager.registerBindsIfNeeded(innerModule);
      manager.unregisterBinds(innerModule);

      final cubitBindType = Bind.getBindByType(ModulesCubitMock)?.runtimeType;
      expect(manager.bindReferences.containsKey(cubitBindType), isTrue);

      final clientBindType = Bind.getBindByType(ModulesClientMock)?.runtimeType;
      expect(manager.bindReferences.containsKey(clientBindType), isTrue);

      final repositoryBindType =
          Bind.getBindByType(ModulesRepositoryMock)?.runtimeType;
      expect(manager.bindReferences.containsKey(repositoryBindType), isTrue);
    },
  );

  test(
    'Root module works independently (The root module should not clear references)',
    () async {
      await startModugoMock(module: rootModule, debugLogDiagnostics: true);

      manager.registerBindsIfNeeded(rootModule);

      final repository = Bind.get<ModulesRepositoryMock>();
      expect(repository, isNotNull);
      expect(repository is ModulesRepositoryMockImpl, isTrue);

      final client = Bind.get<ModulesClientMock>();
      expect(client, isNotNull);
      expect(client is ModulesClientMockImpl, isTrue);
    },
  );

  test('Unregister root module only', () async {
    await startModugoMock(module: rootModule, debugLogDiagnostics: true);

    manager.registerBindsIfNeeded(rootModule);
    manager.registerBindsIfNeeded(innerModule);

    manager.unregisterBinds(rootModule);

    final cubitBindType = Bind.getBindByType(ModulesCubitMock)?.runtimeType;
    expect(manager.bindReferences.containsKey(cubitBindType), isTrue);

    final clientBindType = Bind.getBindByType(ModulesClientMock)?.runtimeType;
    expect(manager.bindReferences.containsKey(clientBindType), isTrue);

    final repositoryBindType =
        Bind.getBindByType(ModulesRepositoryMock)?.runtimeType;
    expect(manager.bindReferences.containsKey(repositoryBindType), isTrue);
  });
}
