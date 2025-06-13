import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/module_route.dart';

void main() {
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
}

final class _DummyModule extends Module {}

final class _FakeBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
