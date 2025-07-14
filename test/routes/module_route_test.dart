import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';

void main() {
  group('ModuleRoute - navigation key', () {
    test('creates ModuleRoute with all optional parameters', () {
      final key = GlobalKey<NavigatorState>();

      final route = ModuleRoute(
        '/produto',
        name: 'produto-module',
        module: _DummyModule(),
        guards: [_GuardAllow()],
        parentNavigatorKey: key,
        redirect: (context, state) async => '/redirected',
        routePattern: RoutePatternModel.from(r'^/produto$'),
      );

      expect(route.path, '/produto');
      expect(route.guards, isNotEmpty);
      expect(route.name, 'produto-module');
      expect(route.parentNavigatorKey, key);
      expect(route.module, isA<_DummyModule>());
      expect(route.routePattern?.regex.pattern, r'^/produto$');
    });
  });

  group('ModuleRoute - equality and hashCode', () {
    test('should be equal when path, name and module are equal', () {
      final module = _DummyModule();

      final a = ModuleRoute('/home', name: 'home', module: module);
      final b = ModuleRoute('/home', name: 'home', module: module);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal when path differs', () {
      final module = _DummyModule();

      final a = ModuleRoute('/home', name: 'x', module: module);
      final b = ModuleRoute('/settings', name: 'x', module: module);

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when name differs', () {
      final module = _DummyModule();

      final a = ModuleRoute('/home', name: 'x', module: module);
      final b = ModuleRoute('/home', name: 'y', module: module);

      expect(a, isNot(equals(b)));
    });

    test('should not be equal when module differs', () {
      final a = ModuleRoute('/home', name: 'x', module: _DummyModule());
      final b = ModuleRoute('/home', name: 'x', module: _DummyModule());

      expect(a, isNot(equals(b)));
    });
  });

  group('ModuleRoute - field assignment', () {
    test('should assign all fields correctly with redirect', () {
      final module = _DummyModule();
      redirectFn(BuildContext context, GoRouterState state) => '/redirected';

      final route = ModuleRoute(
        '/auth',
        name: 'auth',
        module: module,
        redirect: redirectFn,
      );

      expect(route.name, 'auth');
      expect(route.path, '/auth');
      expect(route.module, module);
      expect(route.redirect, isNotNull);
      expect(
        route.redirect!(_FakeBuildContext(), _FakeGoRouterState()),
        equals('/redirected'),
      );
    });

    test('should assign fields correctly without optional values', () {
      final module = _DummyModule();

      final route = ModuleRoute('/about', module: module);

      expect(route.path, '/about');
      expect(route.name, isNull);
      expect(route.module, module);
      expect(route.redirect, isNull);
    });
  });

  group('ModuleRoute - guards', () {
    test('should assign guards list correctly', () {
      final guard1 = _GuardAllow();
      final guard2 = _GuardBlock();
      final module = _DummyModule();

      final route = ModuleRoute(
        '/secure',
        module: module,
        guards: [guard1, guard2],
      );

      expect(route.guards, isNotNull);
      expect(route.guards.length, 2);
      expect(route.guards.first, isA<_GuardAllow>());
      expect(route.guards.last, isA<_GuardBlock>());
    });

    test('should default to empty guards list when not provided', () {
      final module = _DummyModule();
      final route = ModuleRoute('/public', module: module);

      expect(route.guards, isEmpty);
    });

    test('should not affect equality when guards differ', () {
      final module = _DummyModule();

      final a = ModuleRoute(
        '/settings',
        module: module,
        guards: [_GuardAllow()],
      );

      final b = ModuleRoute(
        '/settings',
        module: module,
        guards: [_GuardBlock()],
      );

      expect(a, equals(b));
    });
  });

  group('ModuleRoute with RoutePatternModel', () {
    test('matches correct path and extracts parameters', () {
      final route = ModuleRoute(
        '/product/:id',
        module: _DummyModule(),
        routePattern: RoutePatternModel.from(
          r'^/product/(\d+)$',
          paramNames: ['id'],
        ),
      );

      final pattern = route.routePattern!;
      expect(pattern.regex.hasMatch('/product/42'), isTrue);

      final params = pattern.extractParams('/product/42');
      expect(params, {'id': '42'});
    });

    test('does not match invalid path', () {
      final route = ModuleRoute(
        '/product/:id',
        module: _DummyModule(),
        routePattern: RoutePatternModel.from(
          r'^/product/(\d+)$',
          paramNames: ['id'],
        ),
      );

      final pattern = route.routePattern!;
      expect(pattern.regex.hasMatch('/invalid/42'), isFalse);

      final params = pattern.extractParams('/invalid/42');
      expect(params, isEmpty);
    });

    test('supports multiple parameters in path', () {
      final route = ModuleRoute(
        '/order/:orderId/item/:itemId',
        module: _DummyModule(),
        routePattern: RoutePatternModel.from(
          r'^/order/(\d+)/item/(\w+)$',
          paramNames: ['orderId', 'itemId'],
        ),
      );

      final pattern = route.routePattern!;
      expect(pattern.regex.hasMatch('/order/12/item/abc'), isTrue);

      final params = pattern.extractParams('/order/12/item/abc');
      expect(params, {'orderId': '12', 'itemId': 'abc'});
    });

    test('== returns true for equal routes and patterns', () {
      final module = _DummyModule();

      final routeA = ModuleRoute(
        '/user/:id',
        module: module,
        routePattern: RoutePatternModel.from(
          r'^/user/(\w+)$',
          paramNames: ['id'],
        ),
      );

      final routeB = ModuleRoute(
        '/user/:id',
        module: module,
        routePattern: RoutePatternModel.from(
          r'^/user/(\w+)$',
          paramNames: ['id'],
        ),
      );

      expect(routeA, equals(routeB));
      expect(routeA.hashCode, equals(routeB.hashCode));
    });

    test('== returns false when routePatterns differ', () {
      final routeA = ModuleRoute(
        '/user/:id',
        module: _DummyModule(),
        routePattern: RoutePatternModel.from(
          r'^/user/(\w+)$',
          paramNames: ['id'],
        ),
      );

      final routeB = ModuleRoute(
        '/user/:id',
        module: _DummyModule(),
        routePattern: RoutePatternModel.from(
          r'^/user/(\d+)$',
          paramNames: ['id'],
        ),
      );

      expect(routeA, isNot(equals(routeB)));
    });
  });
}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/', child: (_, __) => const Placeholder()),
  ];
}

final class _FakeBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _GuardAllow implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}

final class _GuardBlock implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/blocked';
}

final class _FakeGoRouterState extends GoRouterState {
  _FakeGoRouterState()
    : super(
        RouteConfiguration(
          ValueNotifier(RoutingConfig(routes: [])),
          navigatorKey: GlobalKey<NavigatorState>(),
        ),
        fullPath: '/',
        uri: Uri.parse('/'),
        matchedLocation: '/',
        pathParameters: const {},
        pageKey: const ValueKey('fake'),
      );
}
