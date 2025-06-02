import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';

import 'implementations_mock.dart';

final class SingleModuleModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton<ModulesClientMock>((_) => ModulesClientMockImpl()),
    Bind.factory<ModulesRepositoryMock>(
      (i) => ModulesRepositoryMockImpl(client: i.get<ModulesClientMock>()),
    ),
    Bind.factory<ModulesCubitMock>(
      (i) => ModulesCubitMock(repository: i.get<ModulesRepositoryMock>()),
    ),
  ];
}
