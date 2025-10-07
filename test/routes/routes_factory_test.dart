import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/routes_factory.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

void main() {
  group('RoutesFactory.from', () {
    test('creates GoRoute for ChildRoute and validates path', () {
      final route = ChildRoute(
        name: 'home',
        path: '/home',
        child: (_, _) => const Placeholder(),
      );

      final result = RoutesFactory.from(route);
      expect(result, isA<GoRoute>());
      expect((result as GoRoute).path, '/home');
    });

    test('applies guard redirect in ChildRoute', () async {
      final route = ChildRoute(
        path: '/feed',
        guards: [_RedirectGuard('/login')],
        child: (_, _) => const Placeholder(),
      );

      final goRoute = RoutesFactory.from(route) as GoRoute;
      final redirect = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(redirect, '/login');
    });

    test('returns null when all guards allow', () async {
      final route = ChildRoute(
        path: '/feed',
        guards: [_AllowGuard()],
        child: (_, _) => const Placeholder(),
      );

      final goRoute = RoutesFactory.from(route) as GoRoute;
      final redirect = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(redirect, isNull);
    });

    test('creates GoRoute for ModuleRoute and validates nested path', () {
      final module = _DummyModule();
      final route = ModuleRoute(path: '/mod', module: module);

      final result = RoutesFactory.from(route);
      expect(result, isA<GoRoute>());
      expect((result as GoRoute).path, '/mod');
    });

    test('applies GuardModuleDecorator redirect', () async {
      final guardedModule = GuardModuleDecorator(
        module: _DummyModule(),
        guards: [_RedirectGuard('/blocked')],
      );

      final route = ModuleRoute(path: '/mod', module: guardedModule);
      final goRoute = RoutesFactory.from(route) as GoRoute;

      final redirect = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(redirect, '/blocked');
    });

    test('creates ShellRoute with nested routes', () {
      final shell = ShellModuleRoute(
        builder: (_, _, child) => child,
        routes: [
          ChildRoute(path: '/a', child: (_, _) => const Text('A')),
          ChildRoute(path: '/b', child: (_, _) => const Text('B')),
        ],
      );

      final result = RoutesFactory.from(shell);
      expect(result, isA<ShellRoute>());

      final shellRoute = result as ShellRoute;
      expect(shellRoute.routes.length, 2);
    });

    test('creates StatefulShellRoute with child branches', () {
      final shell = StatefulShellModuleRoute(
        builder: (_, _, shell) => shell,
        routes: [
          ChildRoute(path: '/', child: (_, _) => const Text('Root')),
          ChildRoute(path: '/tab', child: (_, _) => const Text('Tab')),
        ],
      );

      final result = RoutesFactory.from(shell);
      expect(result, isA<StatefulShellRoute>());

      final shellRoute = result as StatefulShellRoute;
      expect(shellRoute.branches.length, 2);
    });

    test('creates StatefulShellRoute with nested ModuleRoutes', () {
      final shell = StatefulShellModuleRoute(
        builder: (_, _, shell) => shell,
        routes: [
          ModuleRoute(path: '/a', module: _DummyModule()),
          ModuleRoute(path: '/b', module: _DummyModule()),
        ],
      );

      final result = RoutesFactory.from(shell);
      final route = result as StatefulShellRoute;

      expect(route.branches.length, 2);
      expect(route.branches.first.routes.first, isA<GoRoute>());
    });

    test('throws for unsupported IRoute type', () {
      final fake = _UnsupportedRoute();

      expect(() => RoutesFactory.from(fake), throwsA(isA<UnsupportedError>()));
    });

    test('throws ArgumentError on invalid path', () {
      final invalid = ChildRoute(
        path: '/invalid/:(id',
        child: (_, _) => const Placeholder(),
      );

      expect(() => RoutesFactory.from(invalid), throwsA(isA<ArgumentError>()));
    });

    test('safe builder catches errors in build and rethrows', () {
      final route = ChildRoute(
        path: '/',
        child: (_, _) => throw Exception('Boom'),
      );

      final goRoute = RoutesFactory.from(route) as GoRoute;

      expect(
        () => goRoute.builder!(BuildContextFake(), StateFake()),
        throwsException,
      );
    });
  });
}

final class _UnsupportedRoute implements IRoute {}

final class _RedirectGuard implements IGuard<String?> {
  final String redirect;
  _RedirectGuard(this.redirect);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => redirect;
}

final class _AllowGuard implements IGuard<String?> {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _DummyModule extends Module {
  bool called = false;

  @override
  void binds() {
    called = true;
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', name: 'root', child: (_, _) => const Text('Root')),
  ];
}
