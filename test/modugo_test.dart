import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/injector.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/transitions/transition.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules_mock.dart';

void main() {
  test('GoRouterModular.configure sets up router and diagnostics', () async {
    final modugo = await startModugoMock(
      module: RootModuleMock(),
      debugLogDiagnostics: true,
    );

    expect(modugo, isA<GoRouter>());
    expect(Modugo.routerConfig, same(modugo));
    expect(Modugo.debugLogDiagnostics, isTrue);
    expect(Modugo.getDefaultTransition, TypeTransition.fade);
  });

  test(
    'configure should return existing router if already configured',
    () async {
      final first = await startModugoMock(module: RootModuleMock());
      final second = await startModugoMock(module: RootModuleMock());

      expect(first, same(second));
    },
  );

  test('get<T>() retrieves registered bind', () {
    final instance = RootModuleMock();
    Bind.register<RootModuleMock>(Bind.singleton((_) => instance));

    expect(Modugo.get<RootModuleMock>(), same(instance));
  });
}
