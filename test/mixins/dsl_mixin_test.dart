import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  final dsl = _DslModule();

  group('IDsl - child()', () {
    test('should return a ChildRoute with default path', () {
      final route = dsl.child(child: (_, _) => const Placeholder());

      expect(route, isA<ChildRoute>());
      expect(route.path, '/');
      expect(route.name, isNull);
      expect(route.guards, isEmpty);
      expect(route.transition, isNull);
      expect(route.pageBuilder, isNull);
      expect(route.parentNavigatorKey, isNull);
      expect(route.onExit, isNull);
    });

    test('should return a ChildRoute with all parameters', () {
      final key = GlobalKey<NavigatorState>();
      final guard = _GuardAllow();

      final route = dsl.child(
        path: '/home',
        name: 'home',
        guards: [guard],
        parentNavigatorKey: key,
        transition: TypeTransition.fade,
        onExit: (_, _) async => true,
        pageBuilder: (_, _) => const MaterialPage(child: Placeholder()),
        child: (_, _) => const Placeholder(),
      );

      expect(route, isA<ChildRoute>());
      expect(route.path, '/home');
      expect(route.name, 'home');
      expect(route.guards, hasLength(1));
      expect(route.guards.first, same(guard));
      expect(route.transition, TypeTransition.fade);
      expect(route.parentNavigatorKey, same(key));
      expect(route.pageBuilder, isNotNull);
      expect(route.onExit, isNotNull);
    });
  });

  group('IDsl - module()', () {
    test('should return a ModuleRoute with default path', () {
      final inner = _EmptyModule();
      final route = dsl.module(module: inner);

      expect(route, isA<ModuleRoute>());
      expect(route.path, '/');
      expect(route.name, isNull);
      expect(route.parentNavigatorKey, isNull);
    });

    test('should return a ModuleRoute with all parameters', () {
      final inner = _EmptyModule();
      final key = GlobalKey<NavigatorState>();

      final route = dsl.module(
        module: inner,
        name: 'auth',
        parentNavigatorKey: key,
      );

      expect(route, isA<ModuleRoute>());
      expect(route.path, '/');
      expect(route.name, 'auth');
      expect(route.module, same(inner));
      expect(route.parentNavigatorKey, same(key));
    });
  });

  group('IDsl - alias()', () {
    test('should return an AliasRoute with from and to', () {
      final route = dsl.alias(from: '/cart/:id', to: '/order/:id');

      expect(route, isA<AliasRoute>());
      expect(route.from, '/cart/:id');
      expect(route.to, '/order/:id');
    });
  });

  group('IDsl - shell()', () {
    test('should return a ShellModuleRoute with required fields', () {
      final routes = <IRoute>[
        ChildRoute(path: '/a', child: (_, _) => const Placeholder()),
      ];

      final route = dsl.shell(routes: routes, builder: (_, _, child) => child);

      expect(route, isA<ShellModuleRoute>());
      expect(route.routes, same(routes));
      expect(route.observers, isNull);
      expect(route.navigatorKey, isNull);
      expect(route.parentNavigatorKey, isNull);
      expect(route.pageBuilder, isNull);
    });

    test('should return a ShellModuleRoute with all parameters', () {
      final navKey = GlobalKey<NavigatorState>();
      final parentKey = GlobalKey<NavigatorState>();
      final observer = NavigatorObserver();

      final route = dsl.shell(
        routes: [ChildRoute(path: '/b', child: (_, _) => const Placeholder())],
        builder: (_, _, child) => child,
        observers: [observer],
        navigatorKey: navKey,
        parentNavigatorKey: parentKey,
        pageBuilder: (_, _, child) => MaterialPage(child: child),
      );

      expect(route, isA<ShellModuleRoute>());
      expect(route.navigatorKey, same(navKey));
      expect(route.parentNavigatorKey, same(parentKey));
      expect(route.observers, hasLength(1));
      expect(route.pageBuilder, isNotNull);
    });
  });

  group('IDsl - statefulShell()', () {
    test('should return a StatefulShellModuleRoute with required fields', () {
      final route = dsl.statefulShell(
        routes: [ModuleRoute(path: '/tab', module: _EmptyModule())],
        builder: (_, _, shell) => shell,
      );

      expect(route, isA<StatefulShellModuleRoute>());
      expect(route.routes, hasLength(1));
      expect(route.key, isNull);
      expect(route.parentNavigatorKey, isNull);
    });

    test('should return a StatefulShellModuleRoute with all parameters', () {
      final shellKey = GlobalKey<StatefulNavigationShellState>();
      final parentKey = GlobalKey<NavigatorState>();

      final route = dsl.statefulShell(
        routes: [ModuleRoute(path: '/tab', module: _EmptyModule())],
        builder: (_, _, shell) => shell,
        key: shellKey,
        parentNavigatorKey: parentKey,
      );

      expect(route, isA<StatefulShellModuleRoute>());
      expect(route.key, same(shellKey));
      expect(route.parentNavigatorKey, same(parentKey));
    });
  });
}

final class _DslModule extends Module {
  @override
  List<IRoute> routes() => [];
}

final class _EmptyModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}

final class _GuardAllow implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}
