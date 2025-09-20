import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/modules/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

void main() {
  testWidgets('should redirect from ModuleRoute', (tester) async {
    final module = _RedirectingModule();

    Modugo.configure(module: module, initialRoute: '/home');

    await tester.pumpWidget(const _App());

    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
  });
}

final class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: Modugo.routerConfig);
  }
}

final class _RedirectingModule extends Module {
  @override
  List<IRoute> routes() => [
    ModuleRoute(
      path: '/home',
      module: _DummyModule(),
      redirect: (context, state) => '/landing',
    ),
    ChildRoute(path: '/landing', child: (_, _) => const Text('Landing')),
  ];
}

final class _DummyModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Text('Should never reach')),
  ];
}
