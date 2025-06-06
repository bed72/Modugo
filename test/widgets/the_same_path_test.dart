import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/modugo.dart';

void main() {
  testWidgets('should mount HomeModule as initial branch without error', (
    tester,
  ) async {
    final router = await Modugo.configure(
      initialRoute: '/',
      module: _AppModuleMock(),
      debugLogDiagnostics: true,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    expect(find.text('HomeScreen'), findsOneWidget);
  });
}

final class _AppModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    StatefulShellModuleRoute(
      builder: (_, __, shell) => shell,
      routes: [
        ModuleRoute('/', name: 'home-module', module: _HomeModuleMock()),
      ],
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
