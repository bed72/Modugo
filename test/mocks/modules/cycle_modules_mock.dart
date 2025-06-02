import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';

final class CyclicAMock {
  final CyclicBMock b;
  CyclicAMock(this.b);
}

final class CyclicBMock {
  final CyclicAMock a;
  CyclicBMock(this.a);
}

final class CyclicModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.factory<CyclicAMock>((i) => CyclicAMock(i.get<CyclicBMock>())),
    Bind.factory<CyclicBMock>((i) => CyclicBMock(i.get<CyclicAMock>())),
  ];
}
