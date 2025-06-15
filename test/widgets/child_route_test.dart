import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/modugo.dart';

void main() {
  testWidgets('ChildRoute builds widget correctly through GoRouter', (
    tester,
  ) async {
    final childRoute = ChildRoute(
      '/home',
      name: 'home',
      child: (_, __) => const _DummyScreen('Home Page'),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: childRoute.path,
          name: childRoute.name,
          builder: childRoute.child,
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    expect(find.text('Home Page'), findsOneWidget);
  });
}

final class _DummyScreen extends StatelessWidget {
  final String label;
  const _DummyScreen(this.label);

  @override
  Widget build(BuildContext context) => Text(label);
}
