import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

import '../fakes/fakes.dart';

void main() {
  group('Module with AliasRoute', () {
    test('creates GoRoute for alias pointing to valid ChildRoute', () {
      final module = _ModuleWithAlias();
      final routes = module.configureRoutes();

      final alias = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      final page = alias.pageBuilder!(BuildContextFake(), StateFake());

      expect(page, isA<CustomTransitionPage>());
      expect((page as CustomTransitionPage).child, isA<Text>());
    });

    test('multiple aliases can point to the same ChildRoute', () {
      final module = _ModuleWithMultipleAliases();
      final routes = module.configureRoutes();

      final alias1 = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias1',
      );
      final alias2 = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias2',
      );

      expect(alias1.pageBuilder, isNotNull);
      expect(alias2.pageBuilder, isNotNull);
    });

    test('alias respects ChildRoute guards', () async {
      final module = _ModuleWithGuardedAlias();
      final routes = module.configureRoutes();

      final alias = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      final value = await alias.redirect!(BuildContextFake(), StateFake());
      expect(value, '/blocked');
    });

    test('throws ArgumentError if alias points to non-existent ChildRoute', () {
      final module = _ModuleWithBrokenAlias();
      expect(() => module.configureRoutes(), throwsArgumentError);
    });

    test('child and alias coexist in routes', () {
      final module = _ModuleWithAlias();
      final routes = module.configureRoutes();

      final child = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/original',
      );
      final alias = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      expect(child, isNotNull);
      expect(alias, isNotNull);
    });
  });
}

final class _ModuleWithAlias extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/original', child: (_, _) => const Text('Original')),
    AliasRoute(from: '/alias', to: '/original'),
  ];
}

final class _ModuleWithMultipleAliases extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/original', child: (_, _) => const Text('Original')),
    AliasRoute(from: '/alias1', to: '/original'),
    AliasRoute(from: '/alias2', to: '/original'),
  ];
}

final class _ModuleWithGuardedAlias extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/protected',
      child: (_, _) => const Text('Protected'),
      guards: [_BlockGuard()],
    ),
    AliasRoute(from: '/alias', to: '/protected'),
  ];
}

final class _ModuleWithBrokenAlias extends Module {
  @override
  List<IRoute> routes() => [AliasRoute(from: '/alias', to: '/does-not-exist')];
}

final class _BlockGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}
