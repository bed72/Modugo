import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';

abstract interface class CompleteClientMock {
  Future<void> get();
}

final class CompleteClientMockImpl implements CompleteClientMock {
  @override
  Future<void> get() async {}
}

abstract interface class CompleteRepositoryMock {
  Future<void> call();
}

final class CompleteRepositoryMockImpl extends CompleteRepositoryMock {
  final CompleteClientMock client;

  CompleteRepositoryMockImpl({required this.client});

  @override
  Future<void> call() async {}
}

final class CompleteCubitMock {
  final CompleteRepositoryMock repository;
  const CompleteCubitMock({required this.repository});
}

class CompleteModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton<CompleteClientMock>((_) => CompleteClientMockImpl()),
    Bind.factory<CompleteRepositoryMock>(
      (i) => CompleteRepositoryMockImpl(client: i.get<CompleteClientMock>()),
    ),
    Bind.factory<CompleteCubitMock>(
      (i) => CompleteCubitMock(repository: i.get<CompleteRepositoryMock>()),
    ),
  ];
}
