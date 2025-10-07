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
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

void main() {
  test(
    'ChildRoute inside StatefulShell executes guard and redirects',
    () async {
      final shell = StatefulShellModuleRoute(
        builder: (context, state, navShell) => const SizedBox(),
        routes: [
          _child('/feed', guards: [_RedirectGuard('/login')]),
        ],
      );

      final route = RoutesFactory.from(shell) as StatefulShellRoute;
      final branch = route.branches.first;
      final goRoute = branch.routes.first as GoRoute;

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(result, '/login');
    },
  );

  test(
    'ChildRoute inside StatefulShell allows when guard returns null',
    () async {
      final shell = StatefulShellModuleRoute(
        builder: (context, state, navShell) => const SizedBox(),
        routes: [
          _child('/feed', guards: [_AllowGuard()]),
        ],
      );

      final route = RoutesFactory.from(shell) as StatefulShellRoute;
      final branch = route.branches.first;
      final goRoute = branch.routes.first as GoRoute;

      final result = await goRoute.redirect!(BuildContextFake(), StateFake());

      expect(result, isNull);
    },
  );

  test('ModuleRoute inside StatefulShell inherits guards', () async {
    final module = _FakeModule([_child('/deep')]);

    final shell = StatefulShellModuleRoute(
      builder: (context, state, navShell) => const SizedBox(),
      routes: [
        ModuleRoute(
          path: '/mod',
          module: GuardModuleDecorator(
            module: module,
            guards: [_RedirectGuard('/login')],
          ),
        ),
      ],
    );

    final route = RoutesFactory.from(shell) as StatefulShellRoute;
    final branch = route.branches.first;
    final goRoute = branch.routes.first as GoRoute;

    final result = await goRoute.redirect!(BuildContextFake(), StateFake());

    expect(result, '/login');
  });

  test('Multiple branches: only guarded branch redirects', () async {
    final shell = StatefulShellModuleRoute(
      builder: (context, state, navShell) => const SizedBox(),
      routes: [
        _child('/feed', guards: [_RedirectGuard('/login')]),
        _child('/chat', guards: []),
      ],
    );

    final route = RoutesFactory.from(shell) as StatefulShellRoute;

    final feedRoute = route.branches[0].routes.first as GoRoute;
    final chatRoute = route.branches[1].routes.first as GoRoute;

    final feedResult = await feedRoute.redirect!(
      BuildContextFake(),
      StateFake(),
    );
    final chatResult = await chatRoute.redirect!(
      BuildContextFake(),
      StateFake(),
    );

    expect(chatResult, isNull);
    expect(feedResult, '/login');
  });
}

ChildRoute _child(String path, {List<IGuard> guards = const []}) =>
    ChildRoute(path: path, guards: guards, child: (_, _) => const SizedBox());

final class _RedirectGuard implements IGuard<String?> {
  final String redirectTo;
  _RedirectGuard(this.redirectTo);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async =>
      redirectTo;
}

final class _AllowGuard implements IGuard<String?> {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async =>
      null;
}

final class _FakeModule extends Module {
  final List<IRoute> _routes;
  _FakeModule(this._routes);

  @override
  List<IRoute> routes() => _routes;
}
