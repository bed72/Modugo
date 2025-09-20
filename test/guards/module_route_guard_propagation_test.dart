import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';

import 'package:modugo/src/extensions/guard_extension.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

void main() {
  test(
    'ModuleRoute.withInjectedGuards wraps the module with GuardModuleDecorator',
    () {
      final module = _FakeModule([_child('/a')]);

      final route = ModuleRoute(path: '/module', module: module);
      final injected = route.withInjectedGuards([_FakeRedirectGuard('/login')]);

      expect(injected.module, isA<GuardModuleDecorator>());
    },
  );

  test('Injected parent guards appear in children routes of the module', () {
    final parentGuards = [_FakeRedirectGuard('/login')];
    final module = _FakeModule([_child('/a')]);

    final route = ModuleRoute(path: '/module', module: module);
    final injected = route.withInjectedGuards(parentGuards);

    final decorated = injected.module as GuardModuleDecorator;
    final children = decorated.routes();
    final child = children.first as ChildRoute;

    expect(child.guards, isNotEmpty);
    expect(child.guards.first, same(parentGuards.first));
  });

  test(
    'Keeps guard order: parent first, then route guards in module children',
    () {
      final routeGuards = [_FakeAllowGuard()];
      final parentGuards = [_FakeRedirectGuard('/login')];

      final module = _FakeModule([_child('/a', guards: routeGuards)]);

      final route = ModuleRoute(path: '/module', module: module);
      final injected = route.withInjectedGuards(parentGuards);

      final decorated = injected.module as GuardModuleDecorator;
      final children = decorated.routes();
      final child = children.first as ChildRoute;

      expect(child.guards.length, 2);
      expect(child.guards.first, same(parentGuards.first));
      expect(child.guards.last, same(routeGuards.first));
    },
  );

  test('injects parent guards recursively into nested ModuleRoute', () {
    final parentGuards = [_FakeRedirectGuard('/login')];

    final innerModule = _FakeModule([_child('/inner')]);

    final outerModule = _FakeModule([
      ModuleRoute(path: '/innerModule', module: innerModule),
    ]);

    final outerRoute = ModuleRoute(path: '/outer', module: outerModule);

    final injected = outerRoute.withInjectedGuards(parentGuards);

    final decoratedOuter = injected.module as GuardModuleDecorator;
    final outerChildren = decoratedOuter.routes();

    final innerRoute = outerChildren.first as ModuleRoute;
    final decoratedInner = innerRoute.module as GuardModuleDecorator;

    final innerChildren = decoratedInner.routes();
    final innerChild = innerChildren.first as ChildRoute;

    expect(innerChild.guards, isNotEmpty);
    expect(innerChild.guards.first, same(parentGuards.first));
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
