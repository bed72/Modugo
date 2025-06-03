import 'package:modugo/src/module.dart';
import 'package:modugo/src/injectors/sync_injector.dart';

import 'implementations_mock.dart';

final class MultiModulesRootModuleMock extends Module {
  @override
  List<SyncBind> get syncBinds => [
    SyncBind.singleton<ModulesClientMock>((_) => ModulesClientMockImpl()),
    SyncBind.factory<ModulesRepositoryMock>(
      (i) => ModulesRepositoryMockImpl(client: i.getSync<ModulesClientMock>()),
    ),
  ];
}

final class MultiModulesInnerModuleMock extends Module {
  @override
  List<Module> get imports => [MultiModulesRootModuleMock()];

  @override
  List<SyncBind> get syncBinds => [
    SyncBind.factory<ModulesCubitMock>(
      (i) => ModulesCubitMock(repository: i.getSync<ModulesRepositoryMock>()),
    ),
  ];
}
