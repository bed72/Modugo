import 'dart:async';

import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fakes.dart';

void main() {
  test('propagateGuards must apply guard and redirect', () async {
    final module = _ModuleFake();
    final routes = module.routes();
    final child = routes.first as ChildRoute;

    expect(child.guards, isNotEmpty);
    expect(child.guards.first, isA<_GuardFake>());

    final guard = child.guards.first as _GuardFake;
    final data = await guard.call(BuildContextFake(), StateFake());

    expect(data, '/public');
  });

  test('propagateGuards should work with asynchronous guard', () async {
    final module = _ModuleWithAsyncGuardFake();
    final routes = module.routes();
    final child = routes.first as ChildRoute;

    expect(child.guards, isNotEmpty);
    expect(child.guards.first, isA<_AsyncGuardFake>());

    final guard = child.guards.first as _AsyncGuardFake;
    final data = await guard.call(BuildContextFake(), StateFake());

    expect(data, '/login');
  });
}

final class _GuardFake implements IGuard {
  final String redirectTo;

  _GuardFake({required this.redirectTo});

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    return redirectTo;
  }
}

final class _AsyncGuardFake implements IGuard {
  final String redirectTo;

  _AsyncGuardFake({required this.redirectTo});

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    await Future.delayed(Duration(milliseconds: 2));
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
    routes: [ChildRoute(child: (_, __) => const Placeholder())],
  );
}
