import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';

import 'mocks/complete_mock.dart';
import 'mocks/modugo_mock.dart';

void main() {
  late final Manager manager;
  late final CompleteModuleMock module;

  setUp(() async {
    manager = Manager();
    module = CompleteModuleMock();

    manager.bindReferences.clear();
    Bind.clearAll();

    await startModugoMock(module: module, debugLogDiagnostics: true);
  });

  test('Register DemoModule binds and resolve CompleteCubitMock', () {
    manager.registerBindsIfNeeded(module);

    final cubit = Bind.get<CompleteCubitMock>();

    expect(cubit, isNotNull);
    expect(cubit, isA<CompleteCubitMock>());
    expect(cubit.repository, isA<CompleteRepositoryMock>());

    expect(
      manager.bindReferences[CompleteRepositoryMock],
      greaterThanOrEqualTo(1),
    );
    expect(manager.bindReferences[CompleteCubitMock], greaterThanOrEqualTo(1));
  });

  test('Unregister DemoModule binds disposes CompleteCubitMock', () {
    manager.registerBindsIfNeeded(module);
    manager.unregisterBinds(module);

    expect(manager.bindReferences.containsKey(CompleteRepositoryMock), isFalse);
    expect(manager.bindReferences.containsKey(CompleteCubitMock), isFalse);

    expect(() => Bind.get<CompleteCubitMock>(), throwsException);
  });
}
