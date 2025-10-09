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
  group('AliasRoute', () {
    test('creates GoRoute from alias pointing to a ChildRoute', () {
      final module = _AliasModule();
      final routes = module.configureRoutes();

      final aliasRoute = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      expect(aliasRoute.path, '/alias');
      expect(aliasRoute.pageBuilder, isNotNull);
    });

    test('multiple aliases pointing to same ChildRoute', () {
      final module = _MultiAliasModule();
      final routes = module.configureRoutes();

      final alias1 = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias1',
      );
      final alias2 = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias2',
      );

      expect(alias1.path, '/alias1');
      expect(alias2.path, '/alias2');
      expect(alias1.pageBuilder, isNotNull);
      expect(alias2.pageBuilder, isNotNull);
    });

    test('alias respects ChildRoute guards', () async {
      final module = _GuardedAliasModule();
      final routes = module.configureRoutes();

      final alias = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      final value = await alias.redirect!(BuildContextFake(), StateFake());
      expect(value, '/blocked');
    });

    test('alias preserves pageBuilder and transition from ChildRoute', () {
      final module = _CustomPageAliasModule();
      final routes = module.configureRoutes();

      final alias = routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == '/alias',
      );

      expect(alias.pageBuilder, isNotNull);
    });

    test('throws ArgumentError if target ChildRoute does not exist', () {
      final module = _BrokenAliasModule();

      expect(() => module.configureRoutes(), throwsArgumentError);
    });
  });
}

final class _AliasModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/original', child: (_, _) => const Text('Original')),
    AliasRoute(from: '/alias', to: '/original'),
  ];
}

final class _MultiAliasModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/original', child: (_, _) => const Text('Original')),
    AliasRoute(from: '/alias1', to: '/original'),
    AliasRoute(from: '/alias2', to: '/original'),
  ];
}

final class _GuardedAliasModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/protected',
      guards: [_BlockGuard()],
      child: (_, _) => const Text('Protected'),
    ),
    AliasRoute(from: '/alias', to: '/protected'),
  ];
}

final class _CustomPageAliasModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/original',
      child: (_, _) => const Text('Original'),
      pageBuilder:
          (context, state) =>
              const NoTransitionPage(child: Text('Custom Page')),
    ),
    AliasRoute(from: '/alias', to: '/original'),
  ];
}

final class _BrokenAliasModule extends Module {
  @override
  List<IRoute> routes() => [AliasRoute(from: '/alias', to: '/not-exist')];
}

final class _BlockGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}
