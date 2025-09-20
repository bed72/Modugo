import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

void main() {
  group('GuardModuleDecorator', () {
    test('injects guards into base module routes', () {
      final baseRoutes = [
        ChildRoute(path: '/test1', child: (_, _) => Placeholder()),
        ChildRoute(path: '/test2', child: (_, _) => Placeholder()),
      ];

      final mockModule = _ModuleMock(mockRoutes: baseRoutes);
      final guards = [_GuardMock('g1'), _GuardMock('g2')];

      final guardModel = GuardModuleDecorator(
        guards: guards,
        module: mockModule,
      );

      final guardedRoutes = guardModel.routes();

      expect(guardedRoutes.length, baseRoutes.length);
    });

    test('delegates imports call to base module', () {
      final mockImports = [_ModuleMock()];

      final baseModuleWithImports = _ImportMock(mockImports);
      final guardModuleWithImports = GuardModuleDecorator(
        guards: [],
        module: baseModuleWithImports,
      );

      expect(guardModuleWithImports.imports(), mockImports);
    });

    test('runtimeType is the same of the decorated module', () {
      final mockImports = [_ModuleMock()];

      final baseModuleWithImports = _ImportMock(mockImports);
      final guardModuleWithImports = GuardModuleDecorator(
        guards: [],
        module: baseModuleWithImports,
      );

      expect(
        guardModuleWithImports.runtimeType,
        baseModuleWithImports.runtimeType,
      );
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
  final List<IRoute> mockRoutes;

  _ModuleMock({this.mockRoutes = const []});

  @override
  List<IRoute> routes() => mockRoutes;
}

base class _ImportMock extends _ModuleMock {
  final List<Module> _imports;

  _ImportMock(this._imports);

  @override
  List<Module> imports() => _imports;
}
