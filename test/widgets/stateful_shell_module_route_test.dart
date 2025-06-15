import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  setUpAll(() async {
    await Modugo.configure(
      module: _DummyModule(),
      debugLogDiagnostics: false,
      errorBuilder: (_, __) => const Material(child: Text('error')),
    );
  });

  testWidgets('starts on home tab (index 0)', (tester) async {
    await tester.pumpWidget(const _ShellWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('navigates to cart tab via goBranch', (tester) async {
    await tester.pumpWidget(const _ShellWidget());
    await tester.pumpAndSettle();

    final shell = _ShellWidget.lastShell!;
    shell.goBranch(1, initialLocation: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart')), findsOneWidget);
  });

  testWidgets('throws error for unsupported ModuleInterface type', (
    tester,
  ) async {
    final shellRoute = StatefulShellModuleRoute(
      routes: [_UnsupportedRoute()],
      builder: (_, __, ___) => const Placeholder(),
    );

    expect(
      () => shellRoute.toRoute(path: '/', topLevel: true),
      throwsA(isA<UnsupportedError>()),
    );
  });

  testWidgets('navigates to /cart and renders the correct screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const Placeholder(key: Key('home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (_, __) => const Placeholder(key: Key('cart')),
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

  testWidgets('applies initialPathsPerBranch correctly', (tester) async {
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

  testWidgets('integrates both ChildRoute and ModuleRoute', (tester) async {
    final shellRoute = StatefulShellModuleRoute(
      initialPathsPerBranch: ['/', '/page'],
      builder:
          (_, __, shell) => Scaffold(
            body: Column(
              children: [const Text('Shell UI'), Expanded(child: shell)],
            ),
          ),
      routes: [
        ChildRoute(
          '/',
          name: 'child',
          child: (_, __) => const Text('Child Branch'),
        ),
        ModuleRoute('/page', module: _DummyModule()),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [shellRoute.toRoute(path: '', topLevel: true)],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Inner Page'), findsOneWidget);
  });
}

final class _UnsupportedRoute implements ModuleInterface {}

final class _DummyModule extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/', name: 'page', child: (_, __) => const Text('Inner Page')),
  ];
}

final class _ShellWidget extends StatelessWidget {
  const _ShellWidget();

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
                    builder: (_, __) => const Placeholder(key: Key('home')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/cart',
                    builder: (_, __) => const Placeholder(key: Key('cart')),
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
