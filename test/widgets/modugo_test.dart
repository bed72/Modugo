import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/models/route_pattern_model.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  group('Modugo.matchRoute recursive lookup', () {
    test(
      'should match route "/" recursively inside StatefulShellModuleRoute > ModuleRoute > ChildRoute',
      () {
        Modugo.configure(module: _DummyShellModule(), initialRoute: '/');

        final match = Modugo.matchRoute('/');
        expect(match, isNotNull);
        expect(match!.route, isA<ChildRoute>());
      },
    );
  });

  group('Modugo.routeNotifier integration', () {
    testWidgets('routeNotifier emits location changes correctly', (
      tester,
    ) async {
      await Modugo.configure(module: _DummyModule(), initialRoute: '/');

      final notifier = Modugo.routeNotifier;

      String? lastLocation;

      notifier.addListener(() {
        lastLocation = notifier.value;
      });

      notifier.update = '/details';

      await tester.pump();

      expect(lastLocation, isNotNull);
      expect(lastLocation, '/details');
      expect(notifier.value, equals(lastLocation));
    });
  });
}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/', child: (_, __) => const Placeholder()),
    ChildRoute('/details', child: (_, __) => const Placeholder()),
  ];
}

final class _DummyShellModule extends Module {
  @override
  List<IModule> get routes => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => _DummyShellWidget(shell: shell),
      routes: [
        ModuleRoute('/', name: 'home-module', module: _InnerShellModule()),
      ],
    ),
  ];
}

final class _InnerShellModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute(
      '/',
      name: 'home-route',
      child: (_, _) => _DummyScree('Home'),
      routePattern: RoutePatternModel.from(r'^/(\?(origin=fromSignup)?)?$'),
    ),
  ];
}

class _DummyShellWidget extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _DummyShellWidget({required this.shell});

  @override
  Widget build(BuildContext context) {
    return shell;
  }
}

class _DummyScree extends StatelessWidget {
  final String label;

  const _DummyScree(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}
