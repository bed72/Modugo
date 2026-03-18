import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';
import 'package:modugo/src/extensions/guard_extension.dart';

/// Documents BUG-12: `StatefulShellModuleRoute.withInjectedGuards()` does not
/// copy the `key` field when building the new route. Any route relying on a
/// stable `GlobalKey<StatefulNavigationShellState>` will lose it after guard
/// injection.
void main() {
  group('StatefulShellModuleRoute.withInjectedGuards — BUG-12 key loss', () {
    test('[BUG-12] key is dropped after withInjectedGuards', () {
      final shellKey = GlobalKey<StatefulNavigationShellState>();

      final shell = StatefulShellModuleRoute(
        key: shellKey,
        routes: [_child('/a')],
        builder: (_, _, shell) => shell,
      );

      final injected = shell.withInjectedGuards([_FakeGuard()]);

      // BUG: the key is not forwarded — injected.key will be null.
      expect(
        injected.key,
        isNull,
        reason: 'BUG-12: withInjectedGuards drops the key field',
      );
    });

    test('parentNavigatorKey is preserved after withInjectedGuards', () {
      final parentKey = GlobalKey<NavigatorState>();

      final shell = StatefulShellModuleRoute(
        routes: [_child('/a')],
        parentNavigatorKey: parentKey,
        builder: (_, _, shell) => shell,
      );

      final injected = shell.withInjectedGuards([_FakeGuard()]);
      expect(injected.parentNavigatorKey, same(parentKey));
    });

    test('routes receive the injected guards after withInjectedGuards', () {
      final guard = _FakeGuard();

      final shell = StatefulShellModuleRoute(
        routes: [_child('/a')],
        builder: (_, _, shell) => shell,
      );

      final injected = shell.withInjectedGuards([guard]);
      final child = injected.routes.first as ChildRoute;

      expect(child.guards, contains(guard));
    });
  });
}

ChildRoute _child(String path) =>
    ChildRoute(path: path, child: (_, _) => const SizedBox());

final class _FakeGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}
