import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/manager.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/transitions/transition.dart';

import 'mocks/modugo_mock.dart';
import 'mocks/modules_mock.dart';

class HttpClient {}

class DemoRepository {
  final HttpClient client;
  DemoRepository(this.client);
}

class DemoRepositoryImpl extends DemoRepository {
  DemoRepositoryImpl(super.client);
}

class DemoPageCubit {
  final DemoRepository repo;
  DemoPageCubit(this.repo);
}

class DemoModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton<DemoRepository>(
      (i) => DemoRepositoryImpl(i.get<HttpClient>()),
    ),
    Bind.factory<DemoPageCubit>((i) => DemoPageCubit(i.get<DemoRepository>())),
  ];
}

void main() {
  test('GoRouterModular.configure sets up router and diagnostics', () async {
    final modugo = await startModugoMock(
      module: RootModuleMock(),
      debugLogDiagnostics: true,
    );

    expect(modugo, isA<GoRouter>());
    expect(Modugo.routerConfig, same(modugo));
    expect(Modugo.debugLogDiagnostics, isTrue);
    expect(Modugo.getDefaultPageTransition, TypeTransition.fade);
  });

  test(
    'configure should return existing router if already configured',
    () async {
      final first = await startModugoMock(module: RootModuleMock());
      final second = await startModugoMock(module: RootModuleMock());

      expect(first, same(second));
    },
  );

  group('Manager and Bind integration tests', () {
    late Manager manager;
    late DemoModule demoModule;

    setUp(() {
      manager = Manager();
      demoModule = DemoModule();

      // Limpar referências para garantir teste limpo
      manager.bindReferences.clear();
      Bind.dispose(); // método hipotético para limpar registros estáticos do Bind
    });

    test('Register DemoModule binds and resolve DemoPageCubit', () {
      manager.registerBindsIfNeeded(demoModule);

      // Tentar resolver DemoPageCubit
      final cubit = Bind.get<DemoPageCubit>();

      expect(cubit, isNotNull);
      expect(cubit, isA<DemoPageCubit>());
      expect(cubit.repo, isA<DemoRepositoryImpl>());

      // Verificar contagem de referências incrementadas corretamente
      expect(manager.bindReferences[DemoRepository], greaterThanOrEqualTo(1));
      expect(manager.bindReferences[DemoPageCubit], greaterThanOrEqualTo(1));
    });

    test('Unregister DemoModule binds disposes DemoPageCubit', () {
      manager.registerBindsIfNeeded(demoModule);
      manager.unregisterBinds(demoModule);

      // Depois de um unregister, espera-se que as referências sejam removidas
      expect(manager.bindReferences.containsKey(DemoRepository), isFalse);
      expect(manager.bindReferences.containsKey(DemoPageCubit), isFalse);

      // Bind.get deve lançar erro ou retornar null (dependendo da implementação)
      expect(() => Bind.get<DemoPageCubit>(), throwsException);
    });
  });
}
