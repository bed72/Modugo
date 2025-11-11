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
import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
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

      final result = FactoryRoute.from([route]);
      expect(result, hasLength(1));
      expect(result.first, isA<GoRoute>());
      expect((result.first as GoRoute).path, '/home');
    });

    test('applies guard redirect in ChildRoute', () async {
      final route = ChildRoute(
        path: '/feed',
        guards: [_RedirectGuard('/login')],
        child: (_, _) => const Placeholder(),
      );

      final goRoute = FactoryRoute.from([route]).first as GoRoute;
      final redirect = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(redirect, '/login');
    });

    test('returns null when all guards allow', () async {
      final route = ChildRoute(
        path: '/feed',
        guards: [_AllowGuard()],
        child: (_, _) => const Placeholder(),
      );

      final routes = FactoryRoute.from([route]).first as GoRoute;
      final redirect = await routes.redirect!(BuildContextFake(), StateFake());

      expect(redirect, isNull);
    });

    test('creates GoRoute for ModuleRoute and validates nested path', () {
      final module = _DummyModule();
      final route = ModuleRoute(path: '/mod', module: module);

      final result = FactoryRoute.from([route]);
      expect(result.first, isA<GoRoute>());
      expect((result.first as GoRoute).path, '/mod');
    });

    test('throws StateError when ModuleRoute has no ChildRoute', () {
      final module = _EmptyModule();
      final route = ModuleRoute(path: '/empty', module: module);

      expect(() => FactoryRoute.from([route]), throwsA(isA<StateError>()));
    });

    test('applies GuardModuleDecorator redirect', () async {
      final guardedModule = GuardModuleDecorator(
        module: _DummyModule(),
        guards: [_RedirectGuard('/blocked')],
      );

      final route = ModuleRoute(path: '/mod', module: guardedModule);
      final routes = FactoryRoute.from([route]).first as GoRoute;

      final redirect = await routes.redirect!(BuildContextFake(), StateFake());

      expect(redirect, '/blocked');
    });

    test('creates AliasRoute pointing to existing ChildRoute', () async {
      final target = ChildRoute(
        path: '/target',
        guards: [_RedirectGuard('/alias-login')],
        child: (_, _) => const Text('Target'),
      );
      final alias = AliasRoute(from: '/alias', to: '/target');

      final result = FactoryRoute.from([target, alias]);
      expect(result, hasLength(2));

      final aliasRoute = result[1] as GoRoute;
      expect(aliasRoute.path, '/alias');

      final redirect = await aliasRoute.redirect!(
        BuildContextFake(),
        StateFake(),
      );
      expect(redirect, '/alias-login');
    });

    test('throws ArgumentError for invalid AliasRoute target', () {
      final alias = AliasRoute(from: '/alias', to: '/missing');
      expect(() => FactoryRoute.from([alias]), throwsA(isA<ArgumentError>()));
    });

    test('creates ShellRoute with nested routes', () {
      final shell = ShellModuleRoute(
        builder: (_, _, child) => child,
        routes: [
          ChildRoute(path: '/a', child: (_, _) => const Text('A')),
          ChildRoute(path: '/b', child: (_, _) => const Text('B')),
        ],
      );

      final result = FactoryRoute.from([shell]);
      expect(result.first, isA<ShellRoute>());

      final shellRoute = result.first as ShellRoute;
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

      final result = FactoryRoute.from([shell]);
      expect(result.first, isA<StatefulShellRoute>());

      final shellRoute = result.first as StatefulShellRoute;
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

      final result = FactoryRoute.from([shell]);
      final route = result.first as StatefulShellRoute;

      expect(route.branches.length, 2);
      expect(route.branches.first.routes.first, isA<GoRoute>());
    });

    test('throws for unsupported IRoute type', () {
      final fake = _UnsupportedRoute();
      expect(() => FactoryRoute.from([fake]), throwsA(isA<UnsupportedError>()));
    });

    test('throws ArgumentError on invalid path', () {
      final invalid = ChildRoute(
        path: '/invalid/:(id',
        child: (_, _) => const Placeholder(),
      );

      expect(() => FactoryRoute.from([invalid]), throwsA(isA<ArgumentError>()));
    });

    test('safe pageBuilder catches errors in build and rethrows', () async {
      final route = ChildRoute(
        path: '/',
        child: (_, _) => throw Exception('Boom'),
      );

      final routes = FactoryRoute.from([route]).first as GoRoute;

      expect(
        () => routes.pageBuilder!(BuildContextFake(), StateFake()),
        throwsA(isA<Exception>()),
      );
    });

    test('safeAsync catches async errors in guards', () async {
      final route = ChildRoute(
        path: '/',
        guards: [_AsyncErrorGuard()],
        child: (_, _) => const Placeholder(),
      );

      final routes = FactoryRoute.from([route]).first as GoRoute;
      expect(
        () async => await routes.redirect!(BuildContextFake(), StateFake()),
        throwsException,
      );
    });
  });
}

final class _UnsupportedRoute implements IRoute {}

final class _EmptyModule extends Module {
  @override
  List<IRoute> routes() => [];
}

final class _RedirectGuard implements IGuard {
  final String redirect;
  _RedirectGuard(this.redirect);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => redirect;
}

final class _AllowGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _AsyncErrorGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw Exception('Guard failed');
  }
}

final class _DummyModule extends Module {
  bool called = false;

  @override
  void binds() async {
    called = true;
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', name: 'root', child: (_, _) => const Text('Root')),
  ];
}
