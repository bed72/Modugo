import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/guard.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/extensions/guard_extension.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

void main() {
  group('propagateGuards', () {
    test('should apply a synchronous guard and redirect', () async {
      final module = _ModuleFake();
      final routes = module.routes();
      final child = routes.first as ChildRoute;

      expect(child.guards, isNotEmpty);
      expect(child.guards.first, isA<_GuardFake>());

      final guard = child.guards.first as _GuardFake;
      final result = await guard.call(BuildContextFake(), StateFake());

      expect(result, '/public');
    });

    test('should apply an asynchronous guard and redirect', () async {
      final module = _ModuleWithAsyncGuardFake();
      final routes = module.routes();
      final child = routes.first as ChildRoute;

      expect(child.guards, isNotEmpty);
      expect(child.guards.first, isA<_AsyncGuardFake>());

      final guard = child.guards.first as _AsyncGuardFake;
      final result = await guard.call(BuildContextFake(), StateFake());

      expect(result, '/login');
    });

    test('should handle empty guard list gracefully', () {
      final routes = propagateGuards(
        guards: [],
        routes: [ChildRoute(child: (_, _) => const Placeholder())],
      );

      final child = routes.first as ChildRoute;

      expect(child.guards, isEmpty);
    });
  });

  group('ChildRouteExtensions', () {
    test('should prepend parent guards to existing guards', () {
      final parentGuard = _GuardFake(redirectTo: '/parent');
      final existingGuard = _GuardFake(redirectTo: '/existing');

      final route = ChildRoute(
        guards: [existingGuard],
        child: (_, __) => const Placeholder(),
      );

      final data = route.withInjectedGuards([parentGuard]);

      expect(data.guards.first, equals(parentGuard));
      expect(data.guards.last, equals(existingGuard));
    });
  });

  group('ModuleRouteExtensions', () {
    test('should inject parent guards recursively into module routes', () {
      final childModule = _ModuleFake();
      final parentGuard = _GuardFake(redirectTo: '/parent');

      final route = ModuleRoute(module: childModule);

      final data = route.withInjectedGuards([parentGuard]);
      final nestedRoutes = data.module.routes();

      final child = nestedRoutes.first as ChildRoute;
      expect(child.guards.first, equals(parentGuard));
    });
  });

  group('ShellModuleRouteExtensions', () {
    test('should propagate parent guards into all nested routes', () {
      final parentGuard = _GuardFake(redirectTo: '/parent');

      final route = ShellModuleRoute(
        builder: (_, _, _) => const Placeholder(),
        routes: [ChildRoute(child: (_, _) => const Placeholder())],
      );

      final data = route.withInjectedGuards([parentGuard]);
      final child = data.routes.first as ChildRoute;

      expect(child.guards.first, equals(parentGuard));
    });
  });

  group('StatefulShellModuleRouteExtensions', () {
    test('should propagate parent guards into all nested routes', () {
      final parentGuard = _GuardFake(redirectTo: '/parent');

      final route = StatefulShellModuleRoute(
        builder: (_, _, _) => const Placeholder(),
        routes: [ChildRoute(child: (_, _) => const Placeholder())],
      );

      final data = route.withInjectedGuards([parentGuard]);
      final child = data.routes.first as ChildRoute;

      expect(child.guards.first, equals(parentGuard));
    });
  });
}

final class _GuardFake implements IGuard {
  final String redirectTo;
  _GuardFake({required this.redirectTo});

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async =>
      redirectTo;
}

final class _AsyncGuardFake implements IGuard {
  final String redirectTo;
  _AsyncGuardFake({required this.redirectTo});

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    await Future.delayed(const Duration(milliseconds: 2));

    return redirectTo;
  }
}

final class _ModuleFake extends Module {
  @override
  List<IModule> routes() => propagateGuards(
    guards: [_GuardFake(redirectTo: '/public')],
    routes: [ChildRoute(child: (_, _) => const Placeholder())],
  );
}

final class _ModuleWithAsyncGuardFake extends Module {
  @override
  List<IModule> routes() => propagateGuards(
    guards: [_AsyncGuardFake(redirectTo: '/login')],
    routes: [ChildRoute(child: (_, _) => const Placeholder())],
  );
}
