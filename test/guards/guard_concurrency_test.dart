import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/factory_route.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';

final class _FakeBuildContext extends Fake implements BuildContext {}

final class _FakeGoRouterState extends Fake implements GoRouterState {}

GoRoute _route(String path, List<IGuard> guards) {
  final route = ChildRoute(
    path: path,
    guards: guards,
    child: (_, _) => const SizedBox(),
  );
  return FactoryRoute.from([route]).first as GoRoute;
}

void main() {
  late BuildContext ctx;
  late GoRouterState st;

  setUp(() {
    st = _FakeGoRouterState();
    ctx = _FakeBuildContext();
  });

  group('Guard concurrency — CancelableOperation', () {
    test(
      'single execution without concurrency — guard returns null — data preserved',
      () async {
        final goRoute = _route('/test', [_AllowGuard()]);

        expect(await goRoute.redirect!(ctx, st), isNull);
      },
    );

    test(
      'single execution without concurrency — guard returns redirect path — data preserved',
      () async {
        final goRoute = _route('/test', [_RedirectGuard('/login')]);

        expect(await goRoute.redirect!(ctx, st), '/login');
      },
    );

    test(
      'second call arrives before first completes — first returns null',
      () async {
        final completer = Completer<void>();
        final second = _route('/b', [_AllowGuard()]);
        final first = _route('/a', [_SlowAllowGuard(completer.future)]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);

        completer.complete();

        expect(await future1, isNull);
        expect(await future2, isNull);
      },
    );

    test(
      'redirecting guard is cancelled by new navigation — first returns null, second returns its own data',
      () async {
        final completer = Completer<void>();
        final first = _route('/a', [
          _SlowRedirectGuard('/login', completer.future),
        ]);
        final second = _route('/b', [_RedirectGuard('/home')]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);

        completer.complete();

        expect(await future1, isNull);
        expect(await future2, '/home');
      },
    );

    test(
      'multiple guards in sequence without concurrency — first non-null wins, rest are not executed',
      () async {
        bool secondGuardCalled = false;
        final goRoute = _route('/test', [
          _RedirectGuard('/login'),
          _TrackingGuard(() => secondGuardCalled = true),
        ]);

        final data = await goRoute.redirect!(ctx, st);

        expect(data, '/login');
        expect(secondGuardCalled, isFalse);
      },
    );

    test(
      'multiple guards — all return null — all are executed — navigation proceeds',
      () async {
        int callCount = 0;
        final goRoute = _route('/test', [
          _TrackingGuard(() => callCount++),
          _TrackingGuard(() => callCount++),
          _TrackingGuard(() => callCount++),
        ]);

        final data = await goRoute.redirect!(ctx, st);

        expect(data, isNull);
        expect(callCount, 3);
      },
    );

    test(
      'cancellation between guards — data of previous call is discarded',
      () async {
        final completer = Completer<void>();
        final first = _route('/a', [
          _SlowAllowGuard(completer.future),
          _RedirectGuard('/should-be-discarded'),
        ]);
        final second = _route('/b', [_AllowGuard()]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);

        await future2;
        completer.complete();

        expect(await future1, isNull);
      },
    );

    test(
      'three rapid calls in sequence — only the last one delivers its data',
      () async {
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        final first = _route('/a', [
          _SlowRedirectGuard('/route1', completer1.future),
        ]);
        final second = _route('/b', [
          _SlowRedirectGuard('/route2', completer2.future),
        ]);
        final third = _route('/c', [_RedirectGuard('/route3')]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);
        final future3 = third.redirect!(ctx, st);

        completer1.complete();
        completer2.complete();

        expect(await future1, isNull);
        expect(await future2, isNull);
        expect(await future3, '/route3');
      },
    );

    test(
      'guard that throws without concurrency — error is logged and rethrown',
      () {
        final goRoute = _route('/test', [_ThrowingGuard()]);

        expect(() => goRoute.redirect!(ctx, st), throwsA(isA<StateError>()));
      },
    );

    test(
      'guard that throws an exception on a canceled call — returns null without propagating the exception.',
      () async {
        final completer = Completer<void>();
        final second = _route('/b', [_AllowGuard()]);
        final first = _route('/a', [_SlowThrowingGuard(completer.future)]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);

        await future2;
        completer.complete();

        expect(await future1, isNull);
      },
    );

    test(
      'Asynchronous guard with Completer without cancellation — data delivered correctly.',
      () async {
        final completer = Completer<void>();
        final goRoute = _route('/test', [
          _SlowRedirectGuard('/login', completer.future),
        ]);

        final future = goRoute.redirect!(ctx, st);
        completer.complete();

        expect(await future, '/login');
      },
    );

    test(
      'Asynchronous guard canceled mid-flight — returns null even if the underlying Future resolves later.',
      () async {
        final completer = Completer<void>();
        final first = _route('/a', [
          _SlowRedirectGuard('/login', completer.future),
        ]);
        final second = _route('/b', [_AllowGuard()]);

        final future1 = first.redirect!(ctx, st);
        final future2 = second.redirect!(ctx, st);

        await future2;
        completer.complete();

        expect(await future1, isNull);
      },
    );
  });
}

final class _AllowGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => null;
}

final class _RedirectGuard implements IGuard {
  final String to;
  const _RedirectGuard(this.to);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) => to;
}

final class _TrackingGuard implements IGuard {
  final VoidCallback onCalled;
  const _TrackingGuard(this.onCalled);

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    onCalled();
    return null;
  }
}

final class _SlowAllowGuard implements IGuard {
  final Future<void> delay;
  const _SlowAllowGuard(this.delay);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    await delay;
    return null;
  }
}

final class _SlowRedirectGuard implements IGuard {
  final String to;
  final Future<void> delay;
  const _SlowRedirectGuard(this.to, this.delay);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    await delay;
    return to;
  }
}

final class _ThrowingGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    throw StateError('guard failure');
  }
}

final class _SlowThrowingGuard implements IGuard {
  final Future<void> delay;
  const _SlowThrowingGuard(this.delay);

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    await delay;
    throw StateError('guard failure after delay');
  }
}
