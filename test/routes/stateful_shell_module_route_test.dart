import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  group('StatefulShellModuleRoute - equality and hashCode', () {
    test('should be equal when routes and builder match', () {
      builder(BuildContext c, GoRouterState s, StatefulNavigationShell n) =>
          const Placeholder();

      final sharedModule = _DummyModule();

      final a = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute('/home', module: sharedModule)],
      );

      final b = StatefulShellModuleRoute(
        builder: builder,
        routes: [ModuleRoute('/home', module: sharedModule)],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal if builder changes', () {
      final a = StatefulShellModuleRoute(
        routes: [ModuleRoute('/home', module: _DummyModule())],
        builder: (_, __, ___) => const Placeholder(),
      );

      final b = StatefulShellModuleRoute(
        routes: [ModuleRoute('/home', module: _DummyModule())],
        builder: (_, __, ___) => const Text('Different'),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('StatefulShellModuleRoute - path composition', () {
    test('normalizePath should clean up redundant slashes', () {
      final route = StatefulShellModuleRoute(
        routes: [],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(route.normalizePath('///settings//home'), '/settings/home');
      expect(route.normalizePath(''), '/');
    });
  });

  group('StatefulShellModuleRoute - route generation', () {
    test('should throw if route type is unsupported', () {
      final route = StatefulShellModuleRoute(
        routes: [_UnsupportedRoute()],
        builder: (_, __, ___) => const Placeholder(),
      );

      expect(
        () => route.toRoute(path: '/', topLevel: true),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

final class _UnsupportedRoute implements IModule {}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/home', child: (_, __) => const Placeholder()),
  ];
}
