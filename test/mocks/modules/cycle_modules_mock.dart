import 'package:modugo/src/module.dart';
import 'package:modugo/src/injectors/sync_injector.dart';

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
  List<SyncBind> get syncBinds => [
    SyncBind.factory<CyclicAMock>((i) => CyclicAMock(i.getSync<CyclicBMock>())),
    SyncBind.factory<CyclicBMock>((i) => CyclicBMock(i.getSync<CyclicAMock>())),
  ];
}
