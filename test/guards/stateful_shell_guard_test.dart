import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

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

      final route =
          shell.toRoute(path: '/', topLevel: true) as StatefulShellRoute;
      final branch = route.branches.first;
      final goRoute = branch.routes.first as GoRoute;

      final result = await goRoute.redirect!(
        _FakeBuildContext(),
        _FakeGoState(),
      );
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

      final route =
          shell.toRoute(path: '/', topLevel: true) as StatefulShellRoute;
      final branch = route.branches.first;
      final goRoute = branch.routes.first as GoRoute;

      final result = await goRoute.redirect!(
        _FakeBuildContext(),
        _FakeGoState(),
      );
      expect(result, isNull);
    },
  );

  test('ChildRoute guard has priority over local redirect', () async {
    final shell = StatefulShellModuleRoute(
      builder: (context, state, navShell) => const SizedBox(),
      routes: [
        _child(
          '/feed',
          guards: [_RedirectGuard('/login')],
          redirect: (context, state) async => '/other',
        ),
      ],
    );

    final route =
        shell.toRoute(path: '/', topLevel: true) as StatefulShellRoute;
    final branch = route.branches.first;
    final goRoute = branch.routes.first as GoRoute;

    final result = await goRoute.redirect!(_FakeBuildContext(), _FakeGoState());
    expect(result, '/login');
  });

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

    final route =
        shell.toRoute(path: '/', topLevel: true) as StatefulShellRoute;
    final branch = route.branches.first;
    final goRoute = branch.routes.first as GoRoute;

    final result = await goRoute.redirect!(_FakeBuildContext(), _FakeGoState());
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

    final route =
        shell.toRoute(path: '/', topLevel: true) as StatefulShellRoute;

    final feedRoute = route.branches[0].routes.first as GoRoute;
    final chatRoute = route.branches[1].routes.first as GoRoute;

    final feedResult = await feedRoute.redirect!(
      _FakeBuildContext(),
      _FakeGoState(),
    );
    final chatResult = await chatRoute.redirect!(
      _FakeBuildContext(),
      _FakeGoState(),
    );

    expect(chatResult, isNull);
    expect(feedResult, '/login');
  });
}

final class _FakeGoState extends Fake implements GoRouterState {}

final class _FakeBuildContext extends Fake implements BuildContext {}

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
  final List<IModule> _routes;
  _FakeModule(this._routes);

  @override
  List<IModule> routes() => _routes;
}

ChildRoute _child(
  String path, {
  List<IGuard> guards = const [],
  FutureOr<String?> Function(BuildContext, GoRouterState)? redirect,
}) => ChildRoute(
  path: path,
  guards: guards,
  redirect: redirect,
  child: (_, _) => const SizedBox(),
);
