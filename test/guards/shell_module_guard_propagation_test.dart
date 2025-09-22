import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modules/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/registers/binder_registry.dart';
import 'package:modugo/src/extensions/guard_extension.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  test('injects parent guards into ChildRoute inside ShellModuleRoute', () {
    final parentGuards = [_FakeRedirectGuard('/login')];

    final shell = ShellModuleRoute(
      routes: [_child('/a')],
      builder: (_, _, _) => const SizedBox(),
    );

    final injected = shell.withInjectedGuards(parentGuards);

    expect(injected.routes, hasLength(1));

    final child = injected.routes.first as ChildRoute;

    expect(child.guards, isNotEmpty);
    expect(child.guards.first, same(parentGuards.first));
  });

  test('injects parent guards into ModuleRoute inside ShellModuleRoute', () {
    final parentGuards = [_FakeRedirectGuard('/login')];

    final module = _FakeModule([_child('/m1', guards: [])]);

    final shell = ShellModuleRoute(
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
  });

  test(
    'keeps route guard order: parent first, then route guards in ShellModuleRoute',
    () {
      final routeGuards = [_FakeAllowGuard()];
      final parentGuards = [_FakeRedirectGuard('/login')];

      final shell = ShellModuleRoute(
        builder: (_, _, _) => const SizedBox(),
        routes: [_child('/a', guards: routeGuards)],
      );

      final injected = shell.withInjectedGuards(parentGuards);
      final child = injected.routes.first as ChildRoute;

      expect(child.guards.length, 2);
      expect(child.guards.last, same(routeGuards.first));
      expect(child.guards.first, same(parentGuards.first));
    },
  );

  test('injects parent guards recursively when nesting ShellModuleRoute', () {
    final parentGuards = [_FakeRedirectGuard('/login')];

    final innerShell = ShellModuleRoute(
      routes: [_child('/inner')],
      builder: (_, _, _) => const SizedBox(),
    );

    final outerShell = ShellModuleRoute(
      builder: (context, state, child) => const SizedBox(),
      routes: [innerShell],
    );

    final injected = outerShell.withInjectedGuards(parentGuards);
    final injectedInner = injected.routes.first as ShellModuleRoute;

    final innerChild = injectedInner.routes.first as ChildRoute;
    expect(innerChild.guards, isNotEmpty);
    expect(innerChild.guards.first, same(parentGuards.first));
  });

  test(
    'injects parent guards recursively when nesting ShellModuleRoute inside StatefulShellModuleRoute',
    () {
      final parentGuards = [_FakeRedirectGuard('/login')];

      final innerShell = ShellModuleRoute(
        routes: [_child('/inner')],
        builder: (_, _, _) => const SizedBox(),
      );

      final stateful = StatefulShellModuleRoute(
        routes: [innerShell],
        builder: (_, _, _) => const SizedBox(),
      );

      final injected = stateful.withInjectedGuards(parentGuards);
      final injectedInner = injected.routes.first as ShellModuleRoute;

      final innerChild = injectedInner.routes.first as ChildRoute;
      expect(innerChild.guards, isNotEmpty);
      expect(innerChild.guards.first, same(parentGuards.first));
    },
  );
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

final class _FakeModule extends Module {
  final List<IRoute> _routes;
  _FakeModule(this._routes);

  @override
  void binds() {}

  @override
  List<BinderRegistry> imports() => const [];

  @override
  List<IRoute> routes() => _routes;
}

ChildRoute _child(String path, {List<IGuard> guards = const []}) =>
    ChildRoute(path: path, guards: guards, child: (_, _) => const SizedBox());
