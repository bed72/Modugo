import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules_mock.dart';
import 'mocks/services_mock.dart';

void main() {
  late final Manager manager;
  late final SingleModuleModuleMock module;

  setUpAll(() async {
    manager = Manager();
    module = SingleModuleModuleMock();

    manager.bindReferences.clear();
    Bind.clearAll();

    await startModugoMock(module: module, debugLogDiagnostics: true);
  });

  test('Register DemoModule binds and resolve CompleteCubitMock', () {
    manager.registerBindsIfNeeded(module);

    final cubit = Bind.get<ModulesCubitMock>();

    expect(cubit, isNotNull);
    expect(cubit, isA<ModulesCubitMock>());
    expect(cubit.repository, isA<ModulesRepositoryMock>());

    expect(
      manager.bindReferences[Bind<ModulesClientMock>],
      greaterThanOrEqualTo(1),
    );
    expect(
      manager.bindReferences[Bind<ModulesRepositoryMock>],
      greaterThanOrEqualTo(1),
    );
    expect(
      manager.bindReferences[Bind<ModulesCubitMock>],
      greaterThanOrEqualTo(1),
    );
  });

  test(
    'Unregister DemoModule binds disposes CompleteCubitMock (There must be a reference because this module is root)',
    () {
      manager.registerBindsIfNeeded(module);
      manager.unregisterBinds(module);

      expect(
        manager.bindReferences.containsKey(ModulesRepositoryMock),
        isFalse,
      );
      expect(manager.bindReferences.containsKey(ModulesCubitMock), isFalse);
    },
  );
}
