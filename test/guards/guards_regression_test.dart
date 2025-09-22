import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/registers/binder_registry.dart';
import 'package:modugo/src/extensions/guard_extension.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  test(
    'Guards propagate from top-level StatefulShell to deepest ChildRoute',
    () {
      final topGuards = [
        _FakeRedirectGuard('/login'),
        _FakeRedirectGuard('/forbidden'),
      ];

      final innerModule = _FakeModule([_child('/deep')]);
      final moduleRoute = ModuleRoute(path: '/module', module: innerModule);

      final innerShell = ShellModuleRoute(
        routes: [moduleRoute],
        builder: (_, _, _) => const SizedBox(),
      );

      final statefulShell = StatefulShellModuleRoute(
        routes: [innerShell],
        builder: (_, _, _) => const SizedBox(),
      );

      final injected = statefulShell.withInjectedGuards(topGuards);
      final injectedInnerShell = injected.routes.first as ShellModuleRoute;
      final injectedModuleRoute =
          injectedInnerShell.routes.first as ModuleRoute;

      expect(injectedModuleRoute.module, isA<GuardModuleDecorator>());

      final decoratedModule =
          injectedModuleRoute.module as GuardModuleDecorator;

      final children = decoratedModule.routes();
      final deepChild = children.first as ChildRoute;

      expect(deepChild.guards.length, 2);
      expect(deepChild.guards, isNotEmpty);
      expect(deepChild.guards[0], same(topGuards[0]));
      expect(deepChild.guards[1], same(topGuards[1]));
    },
  );

  test(
    'Guards from top-level StatefulShell are prepended before local ChildRoute guards',
    () {
      final topGuards = [
        _FakeRedirectGuard('/login'),
        _FakeRedirectGuard('/forbidden'),
      ];
      final localGuards = [_FakeRedirectGuard('/only-this-page')];

      final innerModule = _FakeModule([_child('/deep', guards: localGuards)]);
      final moduleRoute = ModuleRoute(path: '/module', module: innerModule);

      final innerShell = ShellModuleRoute(
        routes: [moduleRoute],
        builder: (_, _, _) => const SizedBox(),
      );

      final statefulShell = StatefulShellModuleRoute(
        routes: [innerShell],
        builder: (_, _, _) => const SizedBox(),
      );

      final injected = statefulShell.withInjectedGuards(topGuards);
      final injectedInnerShell = injected.routes.first as ShellModuleRoute;
      final injectedModuleRoute =
          injectedInnerShell.routes.first as ModuleRoute;
      final decoratedModule =
          injectedModuleRoute.module as GuardModuleDecorator;
      final deepChild = decoratedModule.routes().first as ChildRoute;

      expect(deepChild.guards.length, 3);
      expect(deepChild.guards, isNotEmpty);

      expect(deepChild.guards[0], same(topGuards[0]));
      expect(deepChild.guards[1], same(topGuards[1]));
      expect(deepChild.guards[2], same(localGuards[0]));
    },
  );
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

ChildRoute _child(String path, {List<IGuard> guards = const []}) => ChildRoute(
  path: path,
  guards: guards,
  child: (context, state) => const SizedBox(),
);
