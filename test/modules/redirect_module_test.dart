import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/redirect_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

import '../fakes/fakes.dart';

void main() {
  group('RedirectRoute - basic', () {
    test('apply simple redirect', () async {
      final module = _ModuleWithRedirect();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/old/:id',
      );

      final state = StateWithParamsFake(
        path: '/old/123',
        params: {'id': '123'},
      );

      final result = await route.redirect!(BuildContextFake(), state);

      expect(result, '/new/123');
    });

    test('does not loop when redirect points to same route', () async {
      final module = _ModuleWithRedirectLoop();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().first;
      final result = await route.redirect!(BuildContextFake(), StateFake());

      expect(result, isNull);
    });
  });

  group('RedirectRoute - with guards', () {
    test('execute guard before redirect', () async {
      final module = _ModuleWithGuardedRedirect();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().first;
      final result = await route.redirect!(BuildContextFake(), StateFake());

      expect(result, '/blocked');
    });
  });

  group('RedirectRoute - inside ModuleRoute', () {
    test('moduleRoute with RedirectRoute works', () async {
      final module = _ParentWithRedirectChild();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/parent',
      );

      final result = await route.redirect!(BuildContextFake(), StateFake());

      expect(result, '/parent/new');
    });
  });

  group('Redirect Route - inside Shell ModuleRoute', () {
    test('works as an alias within the shell', () async {
      final module = _ShellWithRedirect();
      final routes = module.configureRoutes();

      final shell = routes.whereType<ShellRoute>().first;
      final route = shell.routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/alias',
      );

      final result = await route.redirect!(BuildContextFake(), StateFake());

      expect(result, '/real');
    });
  });

  group('Redirect Route - inside Stateful Shell ModuleRoute', () {
    test('redirect is applied within branch', () async {
      final module = _StatefulShellWithRedirect();
      final routes = module.configureRoutes();

      final shell = routes.whereType<StatefulShellRoute>().first;
      final route = shell.branches.first.routes.whereType<GoRoute>().first;
      final result = await route.redirect!(BuildContextFake(), StateFake());

      expect(result, '/tab/new');
    });
  });

  group('RedirectRoute loop prevention', () {
    test('does not loop when redirect resolves to the same path', () async {
      final module = _ModuleWithSelfRedirect();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/cart/:id',
      );

      final state = StateWithParamsFake(path: '/cart/123');
      final result = await route.redirect!(BuildContextFake(), state);

      expect(
        result,
        isNull,
        reason: 'Redirect to the same path must return null to avoid loop',
      );
    });

    test('redirects to a new valid path when params are extracted', () async {
      final module = _ModuleWithCartRedirect();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/cart/:id',
      );

      final state = StateWithParamsFake(path: '/cart/123');
      final result = await route.redirect!(BuildContextFake(), state);

      expect(result, '/order/123');
    });

    test('returns null when redirect params are not matched', () async {
      final module = _ModuleWithCartRedirect();
      final routes = module.configureRoutes();

      final route = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/cart/:id',
      );

      final state = StateWithParamsFake(path: '/cart');
      final result = await route.redirect!(BuildContextFake(), state);

      expect(result, isNull);
    });

    test('multiple RedirectRoutes do not loop each other', () async {
      final module = _ModuleWithMultipleRedirects();
      final routes = module.configureRoutes();

      final first = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/cart/:id',
      );

      final second = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/attachments/:id',
      );

      final state1 = StateWithParamsFake(path: '/cart/123');
      final result1 = await first.redirect!(BuildContextFake(), state1);
      expect(result1, '/order/123');

      final state2 = StateWithParamsFake(path: '/attachments/555');
      final result2 = await second.redirect!(BuildContextFake(), state2);
      expect(result2, '/preview/555');
    });
  });
}

final class _ModuleWithRedirect extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(
      path: '/old/:id',
      redirect: (_, state) => '/new/${state.pathParameters['id']}',
    ),
  ];
}

final class _ModuleWithRedirectLoop extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(path: '/home', redirect: (_, _) => '/home'),
  ];
}

final class _ModuleWithGuardedRedirect extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(
      path: '/secure',
      guards: [AlwaysBlockGuard()],
      redirect: (_, _) => '/after',
    ),
  ];
}

final class _ParentWithRedirectChild extends Module {
  @override
  List<IRoute> routes() => [
    ModuleRoute(path: '/parent', module: _ChildRedirectModule()),
  ];
}

final class _ChildRedirectModule extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(path: '/legacy', redirect: (_, _) => '/parent/new'),
  ];
}

final class _ShellWithRedirect extends Module {
  @override
  List<IRoute> routes() => [
    ShellModuleRoute(
      builder: (_, _, child) => child,
      routes: [
        RedirectRoute(path: '/alias', redirect: (_, _) => '/real'),
        ChildRoute(path: '/real', child: (_, _) => const Placeholder()),
      ],
    ),
  ];
}

final class _StatefulShellWithRedirect extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => shell,
      routes: [
        RedirectRoute(path: '/tab/old', redirect: (_, _) => '/tab/new'),
        ChildRoute(path: '/tab/new', child: (_, _) => const Placeholder()),
      ],
    ),
  ];
}

final class AlwaysBlockGuard implements IGuard<String?> {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}

final class _ModuleWithSelfRedirect extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(path: '/cart/:id', redirect: (_, state) => state.uri.path),
  ];
}

final class _ModuleWithCartRedirect extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(
      path: '/cart/:id',
      redirect: (_, state) {
        final segments = state.uri.pathSegments;
        if (segments.length < 2) return null;
        final id = segments.last;
        return '/order/$id';
      },
    ),
  ];
}

final class _ModuleWithMultipleRedirects extends Module {
  @override
  List<IRoute> routes() => [
    RedirectRoute(
      path: '/cart/:id',
      redirect: (_, state) {
        final id = state.uri.pathSegments.lastOrNull;
        return id == null ? null : '/order/$id';
      },
    ),
    RedirectRoute(
      path: '/attachments/:id',
      redirect: (_, state) {
        final id = state.uri.pathSegments.lastOrNull;
        return id == null ? null : '/preview/$id';
      },
    ),
  ];
}
