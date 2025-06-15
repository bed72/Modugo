import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

void main() {
  setUpAll(() async {
    await Modugo.configure(
      module: _DummyModule(),
      debugLogDiagnostics: false,
      errorBuilder: (_, __) => const Material(child: Text('error')),
    );
  });

  testWidgets('ModuleRoute integrates nested module routes', (tester) async {
    final module = ModuleRoute('/dummy', module: _DummyModule());

    final router = GoRouter(
      initialLocation: '/dummy/page',
      routes: [
        ...module.module.configureRoutes(topLevel: true, path: module.path),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Dummy Page'), findsOneWidget);
  });
}

final class _DummyModule extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/page',
      name: 'page',
      child: (_, __) => const Text('Dummy Page'),
    ),
  ];
}
