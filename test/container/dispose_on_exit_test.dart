// ignore_for_file: unused_element_parameter

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/widgets/module_dispose_scope.dart';

// ─── Test helpers ───────────────────────────────────────────

class _Service {
  bool disposed = false;
  void close() => disposed = true;
}

final class _TestModule extends Module {
  final _Service service;

  _TestModule(this.service);

  @override
  void binds() {
    i.addSingleton<_Service>(() => service, onDispose: (s) => s.close());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Text('test')),
  ];
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  setUp(() {
    Modugo.resetForTest();
    registeredForTest.clear();
  });

  group('ModuleRoute.disposeOnExit', () {
    test('defaults to false', () {
      final route = ModuleRoute(path: '/test', module: _TestModule(_Service()));

      expect(route.disposeOnExit, isFalse);
    });

    test('can be set to true', () {
      final route = ModuleRoute(
        path: '/test',
        module: _TestModule(_Service()),
        disposeOnExit: true,
      );

      expect(route.disposeOnExit, isTrue);
    });
  });

  group('ModuleDisposeScope', () {
    testWidgets('calls module.dispose() when widget is removed from tree', (
      tester,
    ) async {
      final service = _Service();
      final module = _TestModule(service);
      module.configureRoutes();

      // Access service to create the singleton instance
      Modugo.container.get<_Service>();
      expect(service.disposed, isFalse);

      // Mount the widget
      await tester.pumpWidget(
        ModuleDisposeScope(module: module, child: const SizedBox()),
      );

      // Widget is alive — service still active
      expect(service.disposed, isFalse);
      expect(Modugo.container.isRegistered<_Service>(), isTrue);

      // Remove widget from tree (simulates navigation away)
      await tester.pumpWidget(const SizedBox());

      // Module was disposed — service cleaned up
      expect(service.disposed, isTrue);
      expect(Modugo.container.isRegistered<_Service>(), isFalse);
    });

    testWidgets('module can be re-registered after auto-dispose', (
      tester,
    ) async {
      final service1 = _Service();
      final module1 = _TestModule(service1);
      module1.configureRoutes();

      Modugo.container.get<_Service>();

      // Mount and unmount
      await tester.pumpWidget(
        ModuleDisposeScope(module: module1, child: const SizedBox()),
      );
      await tester.pumpWidget(const SizedBox());

      expect(service1.disposed, isTrue);
      expect(registeredForTest.contains(_TestModule), isFalse);

      // Re-register with fresh module
      final service2 = _Service();
      final module2 = _TestModule(service2);
      module2.configureRoutes();

      final resolved = Modugo.container.get<_Service>();
      expect(resolved, same(service2));
      expect(service2.disposed, isFalse);
    });

    testWidgets('does NOT dispose when widget stays in tree', (tester) async {
      final service = _Service();
      final module = _TestModule(service);
      module.configureRoutes();

      Modugo.container.get<_Service>();

      await tester.pumpWidget(
        ModuleDisposeScope(module: module, child: const SizedBox()),
      );

      // Multiple rebuilds — widget stays mounted
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(service.disposed, isFalse);
      expect(Modugo.container.isRegistered<_Service>(), isTrue);
    });
  });
}
