import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_match_extension.dart';
import 'package:modugo/src/extensions/context_navigation_extension.dart';

/// Tests for ERR-5 (matchingRoute) and ERR-6 (canPush) related to path matching.
/// Both use `regExp.hasMatch()` which is a substring search when the regex has
/// no end anchor. In practice, `path_to_regexp` includes anchors for most patterns,
/// so partial matches rarely manifest — but unanchored patterns could be affected.
///
/// These tests verify the expected behavior for common cases.
void main() {
  group('matchingRoute — path matching correctness', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/user/:id',
            name: 'user',
            builder: (_, _) => const _Page('user'),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, _) => const _Page('home'),
          ),
        ],
      );
    });

    testWidgets('matchingRoute returns correct route for full path match', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ctx.matchingRoute('/user/42')?.name, 'user');
    });

    testWidgets('matchingRoute returns null for completely unregistered path', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ctx.matchingRoute('/product/42'), isNull);
    });

    testWidgets(
      'matchingRoute returns null for static path that is only prefix',
      (tester) async {
        // '/hom' is a prefix of '/home' but should not match
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/home');
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(_Page));
        expect(ctx.matchingRoute('/hom'), isNull);
      },
    );

    testWidgets('matchParams extracts id from /user/:id', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/home');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ctx.matchParams('/user/abc'), {'id': 'abc'});
    });
  });

  group('canPush — path matching correctness', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const _Page('home')),
          GoRoute(
            path: '/settings/profile',
            builder: (_, _) => const _Page('profile'),
          ),
          GoRoute(path: '/item/:slug', builder: (_, _) => const _Page('item')),
        ],
      );
    });

    testWidgets('canPush returns true for fully registered static path', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(
        ContextNavigationExtension(ctx).canPush('/settings/profile'),
        isTrue,
      );
    });

    testWidgets('canPush returns true for parameterised route with value', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ContextNavigationExtension(ctx).canPush('/item/my-slug'), isTrue);
    });

    testWidgets('canPush returns false for completely unregistered path', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(
        ContextNavigationExtension(ctx).canPush('/does-not-exist'),
        isFalse,
      );
    });

    testWidgets('canPush returns false for partial prefix of a static path', (
      tester,
    ) async {
      // '/settings' is only a prefix of '/settings/profile', not a full route.
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ContextNavigationExtension(ctx).canPush('/settings'), isFalse);
    });
  });
}

final class _Page extends StatelessWidget {
  final String label;
  const _Page(this.label);

  @override
  Widget build(BuildContext context) => Text(label);
}
