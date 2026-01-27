import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_match_extension.dart';

void main() {
  testWidgets('match extensions return correct results', (tester) async {
    final router = GoRouter(
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/home');
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_Dummy));

    expect(context.isKnownPath('/home'), isTrue);
    expect(context.isKnownPath('/produto/:id'), isTrue);
    expect(context.isKnownPath('/shell/nested'), isTrue);
    expect(context.isKnownPath('/unknown'), isFalse);

    expect(context.isKnownRouteName('home'), isTrue);
    expect(context.isKnownRouteName('nested'), isTrue);
    expect(context.isKnownRouteName('missing'), isFalse);

    final route = context.matchingRoute('/produto/abc123');
    expect(route?.name, 'produto');

    final noMatch = context.matchingRoute('/not-registered');
    expect(noMatch, isNull);

    final params = context.matchParams('/produto/XYZ');
    expect(params, {'id': 'XYZ'});

    final empty = context.matchParams('/home');
    expect(empty, isEmpty);
  });
}

final class _Dummy extends StatelessWidget {
  final String label;
  const _Dummy(this.label);

  @override
  Widget build(BuildContext context) => Text(label);
}
