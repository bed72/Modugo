import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/models/route_pattern_model.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  // TODO FIX-ME:
  // group('Modugo.matchRoute recursive lookup', () {
  //   test(
  //     'should match route "/" recursively inside StatefulShellModuleRoute > ModuleRoute > ChildRoute',
  //     () {
  //       Modugo.configure(module: _DummyShellModule(), initialRoute: '/');

  //       final match = Modugo.matchRoute('/');
  //       expect(match, isNotNull);
  //       expect(match!.route, isA<ChildRoute>());
  //     },
  //   );
  // });
}

final class _DummyShellModule extends Module {
  @override
  List<IRoute> routes() => [
    StatefulShellModuleRoute(
      builder: (_, _, shell) => _DummyShellWidget(shell: shell),
      routes: [
        ModuleRoute(
          path: '/',
          name: 'inner-module',
          module: _InnerShellModule(),
        ),
      ],
    ),
  ];
}

final class _InnerShellModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      name: 'home-route',
      child: (_, _) => _DummyScree('Home'),
      routePattern: RoutePatternModel.from(r'^/(\?(origin=fromSignup)?)?$'),
    ),
  ];
}

final class _DummyShellWidget extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _DummyShellWidget({required this.shell});

  @override
  Widget build(BuildContext context) {
    return shell;
  }
}

final class _DummyScree extends StatelessWidget {
  final String label;

  const _DummyScree(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}
