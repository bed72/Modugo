// ignore_for_file: unnecessary_type_check

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/interfaces/binder_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  group('Module - binder registration', () {
    setUp(Module.clearModules);

    test('registers imported modules before self', () async {
      final inner = _InnerModule();
      final outer = _OuterModule(inner);

      outer.configureRoutes();

      expect(inner.bindCalled, isTrue);
      expect(outer.bindCalled, isTrue);
    });

    test('does not re-register already registered module types', () async {
      final module = _InnerModule();
      module.configureRoutes();
      module.configureRoutes();

      expect(module.bindCallCount, 1);
    });
  });

  group('Module - route creation', () {
    test('configureRoutes returns valid RouteBase list', () {
      final module = _SimpleModule();
      final routes = module.configureRoutes();

      expect(routes.every((r) => r is RouteBase), isTrue);
      expect(routes.isNotEmpty, isTrue);
    });

    test('configureRoutes handles complex module structures', () {
      final module = _ComplexModule();
      final routes = module.configureRoutes();

      expect(routes.whereType<ShellRoute>().isNotEmpty, isTrue);
      expect(routes.whereType<StatefulShellRoute>().isNotEmpty, isTrue);
    });

    test('configureRoutes throws ArgumentError for invalid path', () {
      final module = _InvalidPathModule();

      expect(() => module.configureRoutes(), throwsA(isA<ArgumentError>()));
    });
  });
}

final class _InnerModule extends Module {
  bool bindCalled = false;
  int bindCallCount = 0;

  @override
  void binds() {
    bindCalled = true;
    bindCallCount++;
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}

final class _OuterModule extends Module {
  final Module dependency;
  bool bindCalled = false;

  _OuterModule(this.dependency);

  @override
  List<IBinder> imports() => [dependency];

  @override
  void binds() => bindCalled = true;

  @override
  List<IRoute> routes() => [ModuleRoute(path: '/inner', module: dependency)];
}

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}

final class _ComplexModule extends Module {
  @override
  List<IRoute> routes() => [
    ShellModuleRoute(
      builder: (_, _, child) => child,
      routes: [ChildRoute(path: '/a', child: (_, _) => const Placeholder())],
    ),
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [
        ModuleRoute(path: '/b', module: _SimpleModule()),
        ModuleRoute(path: '/c', module: _SimpleModule()),
      ],
    ),
  ];
}

final class _InvalidPathModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/user/:(id', child: (_, _) => const Placeholder()),
  ];
}
