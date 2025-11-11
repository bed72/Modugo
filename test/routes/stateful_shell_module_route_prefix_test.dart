import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/factory_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

void main() {
  group('StatefulShellModuleRoute - ModuleRoute path prefix', () {
    test('Should prefix all internal module routes with ModuleRoute.path', () {
      final shell = StatefulShellModuleRoute(
        builder: (_, _, _) => const _DummyPage('Shell'),
        routes: [ModuleRoute(path: '/bed', module: _DummyProductsModule())],
      );

      final routes = FactoryRoute.from([shell]);
      expect(routes, isNotEmpty);
      expect(routes.first, isA<StatefulShellRoute>());

      final statefulShell = routes.first as StatefulShellRoute;
      final branches = statefulShell.branches;
      expect(branches.length, 1);

      final routesInBranch =
          branches.first.routes.whereType<GoRoute>().toList();

      expect(routesInBranch, isNotEmpty);
      expect(routesInBranch[0].path, equals('/bed/product'));
      expect(routesInBranch[1].path, equals('/bed/product/add'));
    });

    test(
      'Should not generate duplicate slashes when prefix or child starts with "/"',
      () {
        final shell = StatefulShellModuleRoute(
          builder: (_, _, _) => const _DummyPage('Shell'),
          routes: [ModuleRoute(path: '/bed/', module: _DummyProductsModule())],
        );

        final routes = FactoryRoute.from([shell]);
        final statefulShell = routes.first as StatefulShellRoute;
        final branchRoutes =
            statefulShell.branches.first.routes.whereType<GoRoute>().toList();

        expect(branchRoutes[0].path, equals('/bed/product'));
        expect(branchRoutes[1].path, equals('/bed/product/add'));
      },
    );
  });
}

final class _DummyPage extends StatelessWidget {
  final String label;
  const _DummyPage(this.label);

  @override
  Widget build(BuildContext context) => Text(label);
}

final class _DummyProductsModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/product', child: (_, _) => const _DummyPage('Product')),
    ChildRoute(path: '/product/add', child: (_, _) => const _DummyPage('Add')),
  ];
}
