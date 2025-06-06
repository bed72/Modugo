import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/modugo.dart';

void main() {
  testWidgets('should show splash then navigate to home inside shell', (
    tester,
  ) async {
    final router = await Modugo.configure(
      initialRoute: '/splash',
      module: _AppModuleMock(),
      debugLogDiagnostics: true,
      debugLogDiagnosticsGoRouter: true,
      delayDisposeMilliseconds: 600,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    expect(find.text('SplashScreen'), findsOneWidget);
    expect(find.text('HomeScreen'), findsNothing);

    router.go('/');

    await tester.pumpAndSettle();

    expect(find.text('HomeScreen'), findsOneWidget);
    expect(find.text('SplashScreen'), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
  });
}

final class _AppModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ModuleRoute('/splash', name: 'splash-module', module: _SplashModuleMock()),
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [
        ModuleRoute('/', name: 'home-module', module: _HomeModuleMock()),
      ],
    ),
  ];
}

final class _SplashModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/',
      name: 'splash-route',
      child: (_, __) => const Text('SplashScreen'),
    ),
  ];
}

final class _HomeModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/',
      name: 'home-route',
      child: (_, __) => const Text('HomeScreen'),
    ),
  ];
}
