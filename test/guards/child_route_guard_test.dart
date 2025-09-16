import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/extensions/guard_extension.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

void main() {
  test('ChildRoute default has empty guards list', () {
    final route = ChildRoute(path: '/a', child: (_, _) => const SizedBox());

    expect(route.guards, isEmpty);
  });

  test('withInjectedGuards prepends parent guards to an empty ChildRoute', () {
    final parentGuards = [_FakeRedirectGuard('/login')];
    final route = ChildRoute(path: '/a', child: (_, _) => const SizedBox());

    final injected = route.withInjectedGuards(parentGuards);

    expect(injected.guards, hasLength(1));
    expect(injected.guards.first, same(parentGuards.first));
  });

  test('withInjectedGuards keeps route guards after parent guards', () {
    final routeGuards = [_FakeAllowGuard()];
    final parentGuards = [_FakeRedirectGuard('/login')];

    final route = ChildRoute(
      path: '/a',
      guards: routeGuards,
      child: (_, _) => const SizedBox(),
    );

    final injected = route.withInjectedGuards(parentGuards);

    expect(injected.guards.length, 2);
    expect(injected.guards.last, same(routeGuards.first));
    expect(injected.guards.first, same(parentGuards.first));
  });

  test('multiple parent guards are prepended in the same order', () {
    final parentGuards = [
      _FakeRedirectGuard('/login'),
      _FakeRedirectGuard('/forbidden'),
    ];

    final route = ChildRoute(path: '/a', child: (_, _) => const SizedBox());

    final injected = route.withInjectedGuards(parentGuards);

    expect(injected.guards.length, 2);
    expect(injected.guards[0], same(parentGuards[0]));
    expect(injected.guards[1], same(parentGuards[1]));
  });
}

final class _FakeAllowGuard implements IGuard<String?> {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _FakeRedirectGuard implements IGuard<String?> {
  final String to;
  _FakeRedirectGuard(this.to);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => to;
}
