import 'package:modugo/modugo.dart';

final class NoDisposeMock {}

final class ModuleInterfaceMock implements ModuleInterface {}

final class ServiceMock {
  int value = 0;
}

final class OtherServiceMock {
  final int id;
  OtherServiceMock({this.id = 0});
}

abstract interface class ModulesClientMock {
  Future<void> get();
}

final class ModulesClientMockImpl implements ModulesClientMock {
  @override
  Future<void> get() async {}
}

abstract interface class ModulesRepositoryMock {
  Future<void> call();
}

final class ModulesRepositoryMockImpl extends ModulesRepositoryMock {
  final ModulesClientMock client;

  ModulesRepositoryMockImpl({required this.client});

  @override
  Future<void> call() async {}
}

final class ModulesCubitMock {
  final ModulesRepositoryMock repository;
  const ModulesCubitMock({required this.repository});
}
