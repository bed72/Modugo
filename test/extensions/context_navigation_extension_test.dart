import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_navigation_extension.dart';

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const _Page('home')),
    GoRoute(path: '/about', builder: (_, _) => const _Page('about')),
    GoRoute(
      path: '/profile/:id',
      name: 'profile',
      builder: (_, state) => _Page('profile-${state.pathParameters['id']}'),
    ),
  ],
);

void main() {
  group('ContextNavigationExtension', () {
    late GoRouter router;

    setUp(() => router = _buildRouter());

    // Use explicit extension override (ContextNavigationExtension(ctx)) to
    // disambiguate from GoRouter's own GoRouterHelper extension.

    testWidgets('canPush returns true for a registered path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ContextNavigationExtension(ctx).canPush('/about'), isTrue);
    });

    testWidgets('canPush returns false for an unregistered path', (
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

    testWidgets('go navigates to the target path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      ContextNavigationExtension(ctx).go('/about');
      await tester.pumpAndSettle();

      expect(find.text('about'), findsOneWidget);
    });

    testWidgets('push adds a new route to the stack', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      ContextNavigationExtension(ctx).push('/about');
      await tester.pumpAndSettle();

      expect(find.text('about'), findsOneWidget);
    });

    testWidgets('pop returns to the previous route', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/about');
      await tester.pumpAndSettle();
      expect(find.text('about'), findsOneWidget);

      final ctx = tester.element(find.byType(_Page));
      ContextNavigationExtension(ctx).pop();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('canPop returns false when at the root route', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ContextNavigationExtension(ctx).canPop(), isFalse);
    });

    testWidgets('canPop returns true after push', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/about');
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(ContextNavigationExtension(ctx).canPop(), isTrue);
    });

    testWidgets('goNamed navigates to a named route with path params', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      ContextNavigationExtension(
        ctx,
      ).goNamed('profile', pathParameters: {'id': '42'});
      await tester.pumpAndSettle();

      expect(find.text('profile-42'), findsOneWidget);
    });

    testWidgets('reload does not throw', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(_Page));
      expect(() => ContextNavigationExtension(ctx).reload(), returnsNormally);
    });
  });
}

final class _Page extends StatelessWidget {
  final String label;
  const _Page(this.label);

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}
