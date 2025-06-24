import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';

import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

void main() {
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

  testWidgets('Persistent module is not disposed after navigation', (
    tester,
  ) async {
    final module = ModuleRoute(
      '/persistent',
      module: _PersistentWidgetModule(),
    );
    final router = GoRouter(
      initialLocation: '/persistent/page',
      routes: [
        ...module.module.configureRoutes(topLevel: true, path: module.path),
        GoRoute(
          path: '/other',
          builder: (context, state) => const Text('Other Page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Persistent Page'), findsOneWidget);
    expect(_PersistentWidgetModule.wasRegistered, isTrue);

    router.go('/other');
    await tester.pumpAndSettle();

    await tester.pump(Duration(milliseconds: disposeMilisenconds + 72));

    expect(find.text('Other Page'), findsOneWidget);

    router.go('/persistent/page');
    await tester.pumpAndSettle();

    expect(find.text('Persistent Page'), findsOneWidget);
    expect(_PersistentWidgetModule.wasRegistered, isTrue);
  });
}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      '/page',
      name: 'page',
      child: (_, __) => const Text('Dummy Page'),
    ),
  ];
}

final class _PersistentWidgetModule extends Module {
  static bool wasRegistered = false;

  @override
  bool get persistent => true;

  @override
  void binds(IInjector i) {
    wasRegistered = true;
    i.addSingleton<String>((_) => 'persisted');
  }

  @override
  List<IModule> get routes => [
    ChildRoute(
      '/page',
      name: 'persistent',
      child: (_, __) => const Text('Persistent Page'),
    ),
  ];
}
