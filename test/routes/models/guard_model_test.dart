import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/models/guard_model.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

void main() {
  group('GuardModel', () {
    test('injects guards into base module routes', () {
      final baseRoutes = [
        ChildRoute(path: '/test1', child: (_, _) => Placeholder()),
        ChildRoute(path: '/test2', child: (_, _) => Placeholder()),
      ];

      final mockModule = _ModuleMock(mockRoutes: baseRoutes);
      final guards = [_GuardMock('g1'), _GuardMock('g2')];

      final guardModel = GuardModel(guards: guards, module: mockModule);

      final guardedRoutes = guardModel.routes();

      expect(guardedRoutes.length, baseRoutes.length);
    });

    test('delegates imports call to base module', () {
      final mockImports = [_ModuleMock()];

      final baseModuleWithImports = _ImportMock(mockImports);
      final guardModelWithImports = GuardModel(
        guards: [],
        module: baseModuleWithImports,
      );

      expect(guardModelWithImports.imports(), mockImports);
    });

    test('delegates persistent to base module', () {
      final mockModule = _ModuleMock(persistentValue: true);
      final guardModel = GuardModel(guards: [], module: mockModule);

      expect(guardModel.persistent, isTrue);
    });
  });
}

final class _GuardMock implements IGuard {
  final String id;
  _GuardMock(this.id);

  @override
  Future<String?> call(context, state) async => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _GuardMock && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final class _ModuleMock extends Module {
  final List<IModule> mockRoutes;
  final bool persistentValue;

  _ModuleMock({this.mockRoutes = const [], this.persistentValue = false});

  @override
  List<IModule> routes() => mockRoutes;

  @override
  void binds(IInjector i) {}

  @override
  List<Module> imports() => [];

  @override
  bool get persistent => persistentValue;
}

base class _ImportMock extends _ModuleMock {
  final List<Module> _imports;

  _ImportMock(this._imports);

  @override
  List<Module> imports() => _imports;
}
