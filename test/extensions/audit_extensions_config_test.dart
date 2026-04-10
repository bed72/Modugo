import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/models/route_change_event_model.dart';
import 'package:modugo/src/extensions/context_match_extension.dart';

void main() {
  tearDown(() {
    Modugo.resetForTesting();
    GetIt.instance.reset();
    Event.i.disposeAll();
  });

  // 5.1 — redirectLimit default is 12
  test('Modugo.configure() without explicit redirectLimit uses 12', () async {
    await Modugo.configure(module: _SimpleModule());
    expect(modugoRouter.configuration.redirectLimit, 12);
  });

  // 5.2 — isKnownPath returns true for parameterized route
  testWidgets(
    "isKnownPath('/user/42') returns true when route '/user/:id' exists",
    (tester) async {
      final router = GoRouter(
        routes: [GoRoute(path: '/user/:id', builder: (_, _) => const _Dummy())],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/user/1');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));
      expect(ctx.isKnownPath('/user/42'), isTrue);
    },
  );

  // 5.3 — isKnownPath returns false when no matching route
  testWidgets(
    "isKnownPath('/nonexistent/42') returns false when no matching route",
    (tester) async {
      final router = GoRouter(
        routes: [GoRoute(path: '/user/:id', builder: (_, _) => const _Dummy())],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/user/1');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));
      expect(ctx.isKnownPath('/nonexistent/42'), isFalse);
    },
  );

  // 5.4 — isKnownPath still works for static routes (regression)
  testWidgets(
    "isKnownPath('/settings') returns true for static route (regression)",
    (tester) async {
      final router = GoRouter(
        routes: [GoRoute(path: '/settings', builder: (_, _) => const _Dummy())],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/settings');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));
      expect(ctx.isKnownPath('/settings'), isTrue);
    },
  );

  // 5.5 — isKnownPath with invalid path does not throw
  testWidgets(
    "isKnownPath('/bad path with spaces') returns false without throwing",
    (tester) async {
      final router = GoRouter(
        routes: [GoRoute(path: '/user/:id', builder: (_, _) => const _Dummy())],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/user/1');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      // Must not throw — invalid path just returns false.
      expect(() => ctx.isKnownPath('/bad path with spaces'), returnsNormally);
      expect(ctx.isKnownPath('/bad path with spaces'), isFalse);
    },
  );

  // 5.6 — RouteChangedEventModel emitted via microtask (not synchronously)
  testWidgets('RouteChangedEventModel is emitted asynchronously via microtask, '
      'not synchronously within the addListener callback', (tester) async {
    final received = <RouteChangedEventModel>[];
    Event.i.on<RouteChangedEventModel>(received.add);

    await Modugo.configure(module: _SimpleModule());

    await tester.pumpWidget(MaterialApp.router(routerConfig: modugoRouter));
    await tester.pumpAndSettle();

    // Clear events from initial navigation
    received.clear();

    // Intercept the router delegate to observe the moment the listener fires.
    // We add our spy AFTER Modugo has registered its listener (in configure).
    // When GoRouter notifies, Modugo's listener schedules a Future.microtask.
    // Our spy listener fires right after Modugo's in the same synchronous
    // notification cycle — at that point the event should NOT have arrived yet.
    bool eventArrivedDuringListenerCallback = false;
    modugoRouter.routerDelegate.addListener(() {
      eventArrivedDuringListenerCallback = received.isNotEmpty;
    });

    modugoRouter.go('/about');
    await tester.pumpAndSettle();

    // During the listener callback, the event had not arrived yet (microtask pending)
    expect(eventArrivedDuringListenerCallback, isFalse);

    // After all microtasks, the event has arrived
    expect(received, isNotEmpty);
  });

  // 5.7 — RouteChangedEventModel not emitted when location does not change
  testWidgets(
    'RouteChangedEventModel not emitted when location does not change '
    '(deduplication preserved)',
    (tester) async {
      final received = <RouteChangedEventModel>[];
      Event.i.on<RouteChangedEventModel>(received.add);

      await Modugo.configure(module: _SimpleModule());

      await tester.pumpWidget(MaterialApp.router(routerConfig: modugoRouter));
      await tester.pumpAndSettle();

      // Navigate to /about
      modugoRouter.go('/about');
      await tester.pumpAndSettle();
      await Future<void>.microtask(() {});
      final countAfterFirst = received.length;

      // Navigate to the same location again — no new event expected
      modugoRouter.go('/about');
      await tester.pumpAndSettle();
      await Future<void>.microtask(() {});

      expect(received.length, countAfterFirst);
    },
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final class _Dummy extends StatelessWidget {
  const _Dummy();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const _Dummy()),
    ChildRoute(path: '/about', child: (_, _) => const _Dummy()),
    ChildRoute(path: '/a', child: (_, _) => const _Dummy()),
    ChildRoute(path: '/b', child: (_, _) => const _Dummy()),
    ChildRoute(path: '/c', child: (_, _) => const _Dummy()),
    ChildRoute(path: '/d', child: (_, _) => const _Dummy()),
  ];
}
