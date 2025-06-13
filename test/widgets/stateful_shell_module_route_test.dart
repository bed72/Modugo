import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  testWidgets('starts on home tab (index 0)', (tester) async {
    await tester.pumpWidget(const _ShellMockWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('navigates to cart tab via goBranch', (tester) async {
    await tester.pumpWidget(const _ShellMockWidget());
    await tester.pumpAndSettle();

    final shell = _ShellMockWidget.lastShell!;
    shell.goBranch(1, initialLocation: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart')), findsOneWidget);
  });

  testWidgets('navigates to /cart and renders cart screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder:
                      (context, state) => const Placeholder(key: Key('home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder:
                      (context, state) => const Placeholder(key: Key('cart')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart')), findsOneWidget);
  });

  testWidgets('StatefulShellModuleRoute applies initialPathsPerBranch', (
    tester,
  ) async {
    final route = StatefulShellModuleRoute(
      builder: (_, __, shell) => Scaffold(key: const Key('shell'), body: shell),
      routes: [
        ChildRoute('/', name: 'home', child: (_, __) => const Text('Home')),
        ChildRoute('/cart', name: 'cart', child: (_, __) => const Text('Cart')),
      ],
      initialPathsPerBranch: ['/', '/cart'],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [route.toRoute(path: '', topLevel: true)],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Home'), findsOneWidget);

    final shellWidget = tester.widget<Scaffold>(find.byKey(const Key('shell')));
    final shell = shellWidget.body as StatefulNavigationShell;

    shell.goBranch(1, initialLocation: true);
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsOneWidget);
  });
}

final class _ShellMockWidget extends StatelessWidget {
  const _ShellMockWidget();

  static StatefulNavigationShell? lastShell;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) {
              lastShell = shell;
              return Scaffold(body: shell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder:
                        (context, state) => const Placeholder(key: Key('home')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/cart',
                    builder:
                        (context, state) => const Placeholder(key: Key('cart')),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
