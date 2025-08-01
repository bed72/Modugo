import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
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
      builder: (_, _, ___) => const Placeholder(),
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
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const Placeholder(key: Key('home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (_, _) => const Placeholder(key: Key('cart')),
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

  testWidgets('navigates between branches correctly', (tester) async {
    final route = StatefulShellModuleRoute(
      builder: (_, _, shell) => Scaffold(key: const Key('shell'), body: shell),
      routes: [
        ChildRoute(
          path: '/',
          name: 'home',
          child: (_, _) => const Text('Home'),
        ),
        ChildRoute(
          name: 'cart',
          path: '/cart',
          child: (_, _) => const Text('Cart'),
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [route.toRoute(path: '', topLevel: true)],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    final shellWidget = tester.widget<Scaffold>(find.byKey(const Key('shell')));
    final shell = shellWidget.body as StatefulNavigationShell;

    shell.goBranch(1);
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsOneWidget);
  });

  testWidgets('navigate with GoRouter and keep StatefulShellRoute visible', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const Text('Home')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/page',
                  builder: (_, _) => const Text('Inner Page'),
                ),
              ],
            ),
          ],
          builder:
              (_, _, shell) => Scaffold(
                body: Column(
                  children: [const Text('Shell UI'), Expanded(child: shell)],
                ),
              ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    router.go('/page');
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Inner Page'), findsOneWidget);
  });

  testWidgets('navigate to ModuleRoute dynamic route inside shell', (
    tester,
  ) async {
    final shellRoute = StatefulShellModuleRoute(
      builder: (_, _, shell) {
        return Scaffold(
          body: Column(
            children: [const Text('Shell UI'), Expanded(child: shell)],
          ),
        );
      },
      routes: [
        ChildRoute(
          path: '/',
          name: 'home',
          child: (_, _) => const Text('Home'),
        ),
        ModuleRoute(path: '/', module: _ProductModule()),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      errorBuilder: (_, _) => const Text('ERRO NA ROTA'),
      routes: [shellRoute.toRoute(path: '', topLevel: true)],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    router.go('/cafe/dp/12345');
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Name: cafe Code: 12345'), findsOneWidget);
  });

  testWidgets('navigate to ModuleRoute route inside shell', (tester) async {
    final shellRoute = StatefulShellModuleRoute(
      builder: (_, _, shell) {
        return Scaffold(
          body: Column(
            children: [const Text('Shell UI'), Expanded(child: shell)],
          ),
        );
      },
      routes: [
        ChildRoute(
          path: '/',
          name: 'child',
          child: (_, _) => const Text('Child Branch'),
        ),
        ModuleRoute(path: '/', module: _DummyModule()),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      errorBuilder: (_, _) => const Text('ERRO NA ROTA'),
      routes: [shellRoute.toRoute(path: '', topLevel: true)],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Child Branch'), findsOneWidget);

    router.go('/shell/page');
    await tester.pumpAndSettle();

    expect(find.text('Shell UI'), findsOneWidget);
    expect(find.text('Inner Page'), findsOneWidget);
  });
}

final class _UnsupportedRoute implements IModule {}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      name: 'page',
      path: '/shell/page',
      child: (_, _) => const Text('Inner Page'),
    ),
  ];
}

final class _ProductModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      path: '/',
      name: 'safe-root-route',
      child: (_, _) => const SizedBox.shrink(),
    ),
    ChildRoute(
      name: 'produto_details',
      path: '/:name/dp/:webcode',
      child: (_, state) {
        final name = state.pathParameters['name'];
        final webcode = state.pathParameters['webcode'];
        return Text('Name: $name Code: $webcode');
      },
    ),
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
                    builder: (_, _) => const Placeholder(key: Key('home')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/cart',
                    builder: (_, _) => const Placeholder(key: Key('cart')),
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
