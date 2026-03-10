import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
import 'package:modugo/src/interfaces/guard_interface.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeGoRouterState extends Fake implements GoRouterState {}

void main() {
  late BuildContext fakeContext;
  late GoRouterState fakeState;

  setUp(() {
    fakeContext = _FakeBuildContext();
    fakeState = _FakeGoRouterState();
  });

  group('Guard exception handling', () {
    test('sync guard that throws propagates the exception', () {
      final route = ChildRoute(
        path: '/test',
        guards: [_ThrowingSyncGuard()],
        child: (_, _) => const SizedBox(),
      );

      final goRoutes = FactoryRoute.from([route]);
      final goRoute = goRoutes.first as GoRoute;

      expect(
        () => goRoute.redirect!(fakeContext, fakeState),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'sync guard failure',
        )),
      );
    });

    test('async guard that throws propagates the exception', () {
      final route = ChildRoute(
        path: '/test',
        guards: [_ThrowingAsyncGuard()],
        child: (_, _) => const SizedBox(),
      );

      final goRoutes = FactoryRoute.from([route]);
      final goRoute = goRoutes.first as GoRoute;

      expect(
        () => goRoute.redirect!(fakeContext, fakeState),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'async guard failure',
        )),
      );
    });

    test('first guard passes but second guard throws', () async {
      var firstGuardCalled = false;

      final route = ChildRoute(
        path: '/test',
        guards: [
          _TrackingAllowGuard(() => firstGuardCalled = true),
          _ThrowingSyncGuard(),
        ],
        child: (_, _) => const SizedBox(),
      );

      final goRoutes = FactoryRoute.from([route]);
      final goRoute = goRoutes.first as GoRoute;

      expect(
        () => goRoute.redirect!(fakeContext, fakeState),
        throwsA(isA<StateError>()),
      );

      // Allow microtask to complete for async redirect
      await Future<void>.delayed(Duration.zero);

      expect(firstGuardCalled, isTrue);
    });

    test('guard that redirects before a throwing guard prevents the exception',
        () async {
      final route = ChildRoute(
        path: '/test',
        guards: [
          _RedirectGuard('/login'),
          _ThrowingSyncGuard(),
        ],
        child: (_, _) => const SizedBox(),
      );

      final goRoutes = FactoryRoute.from([route]);
      final goRoute = goRoutes.first as GoRoute;

      final result = await goRoute.redirect!(fakeContext, fakeState);

      expect(result, '/login');
    });
  });
}

final class _ThrowingSyncGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    throw StateError('sync guard failure');
  }
}

final class _ThrowingAsyncGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    throw StateError('async guard failure');
  }
}

final class _TrackingAllowGuard implements IGuard {
  final VoidCallback onCalled;
  _TrackingAllowGuard(this.onCalled);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    onCalled();
    return null;
  }
}

final class _RedirectGuard implements IGuard {
  final String to;
  _RedirectGuard(this.to);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => to;
}
