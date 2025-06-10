import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';
import 'package:modugo/src/extension.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const _DummyScreen(),
        ),
        GoRoute(
          path: '/next',
          name: 'next',
          builder: (context, state) => const _DummyScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/shell-child',
              name: 'shell-child',
              builder: (context, state) => const _DummyScreen(),
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('getExtra returns typed extra', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next', extra: _DummyExtra('test'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    final extra = context.getExtra<_DummyExtra>();

    expect(extra, isNotNull);
    expect(extra!.value, equals('test'));
  });

  testWidgets('argumentsOrThrow throws when wrong type', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next', extra: 'invalid');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    expect(() => context.argumentsOrThrow<_DummyExtra>(), throwsException);
  });

  testWidgets('locationSegments returns path parts', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next?tab=1');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    expect(context.locationSegments, contains('next'));
  });

  testWidgets('reload navigates to same URI', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next?reload=1');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    final uriBefore = context.state.uri.toString();

    context.reload();
    await tester.pumpAndSettle();

    final uriAfter = context.state.uri.toString();
    expect(uriBefore, equals(uriAfter));
  });

  testWidgets('getIntQueryParam parses int correctly', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next?value=42');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    expect(context.getIntQueryParam('value'), equals(42));
  });

  testWidgets('getBoolQueryParam parses bool correctly', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next?flag=true');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));
    expect(context.getBoolQueryParam('flag'), isTrue);
  });

  testWidgets('isKnownPath finds direct GoRoute', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownPath('/next'), isTrue);
  });

  testWidgets('isKnownPath finds ShellRoute child', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownPath('/shell-child'), isTrue);
  });

  testWidgets('isKnownPath returns false for unknown path', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownPath('/not-found'), isFalse);
  });

  testWidgets('isKnownRouteName finds direct GoRoute name', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownRouteName('home'), isTrue);
  });

  testWidgets('isKnownRouteName finds ShellRoute child name', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownRouteName('shell-child'), isTrue);
  });

  testWidgets('isKnownRouteName returns false for unknown name', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final context = tester.element(find.byType(_DummyScreen));
    expect(context.isKnownRouteName('invalid-name'), isFalse);
  });

  testWidgets('isKnownPath recognize route with dynamic path (:id)', (
    tester,
  ) async {
    final dynamicRouter = GoRouter(
      initialLocation: '/product/123',
      routes: [
        GoRoute(
          path: '/product/:id',
          name: 'product-details',
          builder: (context, state) => const _DummyScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: dynamicRouter));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));

    expect(context.isKnownPath('/product/:id'), isTrue);
    expect(context.isKnownPath('/product/123'), isFalse);
    expect(context.isKnownRouteName('product-details'), isTrue);
  });

  testWidgets('Query parameters do not affect isKnownPath', (tester) async {
    final queryRouter = GoRouter(
      initialLocation: '/search?term=modugo',
      routes: [
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const _DummyScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: queryRouter));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));

    expect(context.isKnownPath('/search'), isTrue);
    expect(context.isKnownPath('/search?term=modugo'), isFalse);
  });

  testWidgets('Redirect route is still considered a known route', (
    tester,
  ) async {
    final redirectRouter = GoRouter(
      initialLocation: '/legacy',
      routes: [
        GoRoute(path: '/legacy', redirect: (_, __) => '/modern'),
        GoRoute(
          path: '/modern',
          name: 'modern',
          builder: (context, state) => const _DummyScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: redirectRouter));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_DummyScreen));

    expect(context.isKnownPath('/legacy'), isTrue);
    expect(context.isKnownPath('/modern'), isTrue);
    expect(context.isKnownRouteName('modern'), isTrue);
  });
}

final class _DummyExtra {
  final String value;
  _DummyExtra(this.value);
}

final class _DummyScreen extends StatelessWidget {
  const _DummyScreen();
  @override
  Widget build(BuildContext context) => const Placeholder();
}
