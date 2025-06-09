import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';
import 'package:modugo/src/extension.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const _DummyScreen()),
        GoRoute(
          path: '/next',
          name: 'next',
          builder: (context, state) => const _DummyScreen(),
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
