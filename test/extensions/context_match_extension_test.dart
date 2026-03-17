import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_match_extension.dart';

// Shared router used across all tests in this file.
GoRouter _buildRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, _) => const _Dummy('home'),
    ),
    GoRoute(
      path: '/produto/:id',
      name: 'produto',
      builder: (_, _) => const _Dummy('produto'),
    ),
    ShellRoute(
      builder: (_, _, child) => child,
      routes: [
        GoRoute(
          path: '/shell/nested',
          name: 'nested',
          builder: (_, _) => const _Dummy('nested'),
        ),
      ],
    ),
  ],
);

void main() {
  group('ContextMatchExtension', () {
    late GoRouter router;

    setUp(() => router = _buildRouter());

    testWidgets('isKnownPath returns true for registered paths', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.isKnownPath('/home'), isTrue);
      expect(ctx.isKnownPath('/produto/:id'), isTrue);
      expect(ctx.isKnownPath('/shell/nested'), isTrue);
    });

    testWidgets('isKnownPath returns false for unknown path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.isKnownPath('/unknown'), isFalse);
    });

    testWidgets('isKnownRouteName returns true for registered names', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.isKnownRouteName('home'), isTrue);
      expect(ctx.isKnownRouteName('nested'), isTrue);
    });

    testWidgets('isKnownRouteName returns false for unknown name', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.isKnownRouteName('missing'), isFalse);
    });

    testWidgets('matchingRoute returns route for known path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));
      final route = ctx.matchingRoute('/produto/abc123');

      expect(route?.name, 'produto');
    });

    testWidgets('matchingRoute returns null for unknown path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.matchingRoute('/not-registered'), isNull);
    });

    testWidgets('matchParams extracts path parameters', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));
      final params = ctx.matchParams('/produto/XYZ');

      expect(params, {'id': 'XYZ'});
    });

    testWidgets('matchParams returns empty map for path without params', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Dummy));

      expect(ctx.matchParams('/home'), isEmpty);
    });
  });
}

final class _Dummy extends StatelessWidget {
  final String label;
  const _Dummy(this.label);

  @override
  Widget build(BuildContext context) => Text(label);
}
