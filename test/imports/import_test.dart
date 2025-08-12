import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/managers/injector_manager.dart';

import 'package:modugo/src/interfaces/injector_interface.dart';

void main() {
  test('should register binds from imported modules', () {
    final module = _MainModule();

    InjectorManager().registerBindsAppModule(module);

    expect(Modugo.get<_Shared>(), isA<_Shared>());
    expect(Modugo.get<_Service>(), isA<_Service>());
  });
}

final class _Shared {}

final class _Service {}

final class _MainModule extends Module {
  @override
  List<Module> imports() => [_ImportedModule()];

  @override
  void binds(IInjector i) {
    i.addSingleton((_) => _Service());
  }
}

final class _ImportedModule extends Module {
  @override
  void binds(IInjector i) {
    i.addSingleton((_) => _Shared());
  }
}
