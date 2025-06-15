import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

void main() {
  testWidgets('ShellModuleRoute builds shell and nested route', (tester) async {
    final homeRoute = ChildRoute(
      '/home',
      name: 'home',
      child: (_, __) => const Text('Home View'),
    );

    final shell = ShellModuleRoute(
      routes: [homeRoute],
      builder:
          (context, state, child) => Scaffold(
            body: Column(
              children: [const Text('Shell Wrapper'), Expanded(child: child)],
            ),
          ),
    );

    final goRouter = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          navigatorKey: shell.navigatorKey,
          builder: shell.builder!,
          routes: [
            GoRoute(
              path: '/home',
              name: homeRoute.name,
              builder: homeRoute.child,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();

    expect(find.text('Shell Wrapper'), findsOneWidget);
    expect(find.text('Home View'), findsOneWidget);
  });
}
