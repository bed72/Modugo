import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/extensions/guard_extension.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  test('injects parent guards into ChildRoute branch of StatefulShell', () {
    final parentGuards = [_FakeRedirectGuard('/login')];

    final shell = StatefulShellModuleRoute(
      routes: [_child('/a')],
      builder: (_, _, _) => const SizedBox(),
    );

    final injected = shell.withInjectedGuards(parentGuards);

    expect(injected.routes, hasLength(1));

    final child = injected.routes.first as ChildRoute;

    expect(child.guards, isNotEmpty);
    expect(child.guards.first, same(parentGuards.first));
  });

  test(
    'injects parent guards into ModuleRoute branch (deep child receives it)',
    () {
      final parentGuards = [_FakeRedirectGuard('/login')];

      final module = _FakeModule([_child('/m1', guards: [])]);

      final shell = StatefulShellModuleRoute(
        builder: (_, _, _) => const SizedBox(),
        routes: [ModuleRoute(path: '/module', module: module)],
      );

      final injected = shell.withInjectedGuards(parentGuards);
      final modRoute = injected.routes.first as ModuleRoute;

      final decorated = modRoute.module as GuardModuleDecorator;
      final decoratedChildren = decorated.routes();
      final child = decoratedChildren.first as ChildRoute;

      expect(child.guards, isNotEmpty);
      expect(child.guards.first, same(parentGuards.first));
    },
  );

  test('keeps route guard order: parent first, then route guards', () {
    final routeGuards = [_FakeAllowGuard()];
    final parentGuards = [_FakeRedirectGuard('/login')];

    final shell = StatefulShellModuleRoute(
      builder: (_, _, _) => const SizedBox(),
      routes: [_child('/a', guards: routeGuards)],
    );

    final injected = shell.withInjectedGuards(parentGuards);
    final child = injected.routes.first as ChildRoute;

    expect(child.guards.length, 2);
    expect(child.guards.last, same(routeGuards.first));
    expect(child.guards.first, same(parentGuards.first));
  });

  test(
    'IGuard<void> returns void (treated as null) and can do side-effects',
    () async {
      var called = false;

      final guard = _VoidGuard(() => called = true);
      await guard(_FakeCtx(), _FakeState());

      expect(called, isTrue);
    },
  );
}

final class _FakeCtx extends Fake implements BuildContext {}

final class _FakeState extends Fake implements GoRouterState {}

final class _FakeAllowGuard implements IGuard<String?> {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _VoidGuard implements IGuard<void> {
  final void Function() onCall;
  _VoidGuard(this.onCall);

  @override
  FutureOr<void> call(BuildContext context, GoRouterState state) {
    onCall();
  }
}

final class _FakeRedirectGuard implements IGuard<String?> {
  final String to;
  _FakeRedirectGuard(this.to);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => to;
}

final class _FakeModule extends Module {
  final List<IRoute> _routes;
  _FakeModule(this._routes);

  @override
  void binds() {}

  @override
  List<Module> imports() => const [];

  @override
  List<IRoute> routes() => _routes;
}

ChildRoute _child(String path, {List<IGuard> guards = const []}) =>
    ChildRoute(path: path, guards: guards, child: (_, _) => const SizedBox());
