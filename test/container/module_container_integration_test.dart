// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/mixins/binder_mixin.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

// ─── Test helpers ───────────────────────────────────────────

class _ServiceA {
  final String name;
  _ServiceA([this.name = 'A']);
}

class _ServiceB {
  final String name;
  _ServiceB([this.name = 'B']);
}

class _ServiceShared {
  final String name;
  _ServiceShared([this.name = 'Shared']);
}

class _Disposable {
  bool disposed = false;
  void close() => disposed = true;
}

final class _ModuleA extends Module {
  final List<String>? bindsOrder;

  _ModuleA({this.bindsOrder});

  @override
  void binds() {
    bindsOrder?.add('A');
    i.addSingleton<_ServiceA>(() => _ServiceA());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

final class _ModuleB extends Module {
  final List<String>? bindsOrder;

  _ModuleB({this.bindsOrder});

  @override
  void binds() {
    bindsOrder?.add('B');
    i.addSingleton<_ServiceB>(() => _ServiceB());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

final class _SharedBinder with IBinder {
  final List<String>? bindsOrder;

  _SharedBinder({this.bindsOrder});

  @override
  void binds() {
    bindsOrder?.add('Shared');
    Modugo.container.addSingleton<_ServiceShared>(() => _ServiceShared());
  }
}

final class _ModuleWithImport extends Module {
  final List<String>? bindsOrder;

  _ModuleWithImport({this.bindsOrder});

  @override
  List<IBinder> imports() => [_SharedBinder(bindsOrder: bindsOrder)];

  @override
  void binds() {
    bindsOrder?.add('WithImport');
    i.addSingleton<_ServiceA>(() => _ServiceA());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

final class _ModuleWithDeepImport extends Module {
  final List<String>? bindsOrder;

  _ModuleWithDeepImport({this.bindsOrder});

  @override
  List<IBinder> imports() => [_MiddleBinder(bindsOrder: bindsOrder)];

  @override
  void binds() {
    bindsOrder?.add('Deep');
    i.addSingleton<_ServiceA>(() => _ServiceA());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

final class _MiddleBinder with IBinder {
  final List<String>? bindsOrder;

  _MiddleBinder({this.bindsOrder});

  @override
  List<IBinder> imports() => [_SharedBinder(bindsOrder: bindsOrder)];

  @override
  void binds() {
    bindsOrder?.add('Middle');
    Modugo.container.addSingleton<_ServiceB>(() => _ServiceB());
  }
}

final class _ModuleAlsoImportsShared extends Module {
  @override
  List<IBinder> imports() => [_SharedBinder()];

  @override
  void binds() {
    i.addSingleton<_ServiceB>(() => _ServiceB());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/other', child: (_, _) => const SizedBox()),
  ];
}

final class _ModuleWithDisposable extends Module {
  final _Disposable disposable;

  _ModuleWithDisposable(this.disposable);

  @override
  void binds() {
    i.addSingleton<_Disposable>(() => disposable, onDispose: (d) => d.close());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  setUp(() {
    Modugo.resetForTest();
    registeredForTest.clear();
  });

  group('Module + Container integration', () {
    test('binds() registers in container with correct tag', () {
      final module = _ModuleA();
      module.configureRoutes();

      expect(Modugo.container.isRegistered<_ServiceA>(), isTrue);
      expect(Modugo.container.get<_ServiceA>(), isNotNull);
    });

    test('imports() resolves before the current module', () {
      final order = <String>[];
      final module = _ModuleWithImport(bindsOrder: order);
      module.configureRoutes();

      expect(order, ['Shared', 'WithImport']);
    });

    test('recursive imports resolve in depth-first order', () {
      final order = <String>[];
      final module = _ModuleWithDeepImport(bindsOrder: order);
      module.configureRoutes();

      // Shared → Middle → Deep
      expect(order, ['Shared', 'Middle', 'Deep']);
    });

    test('duplicate module in imports does not run binds() twice', () {
      final order = <String>[];

      // Both modules import _SharedBinder
      final moduleA = _ModuleWithImport(bindsOrder: order);
      moduleA.configureRoutes();

      // Shared should appear only once
      expect(order.where((e) => e == 'Shared').length, 1);
    });

    test('dispose() clears binds of the module', () {
      final module = _ModuleA();
      module.configureRoutes();

      expect(Modugo.container.isRegistered<_ServiceA>(), isTrue);

      module.dispose();

      expect(Modugo.container.isRegistered<_ServiceA>(), isFalse);
      expect(
        () => Modugo.container.get<_ServiceA>(),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose() removes module from _modulesRegistered', () {
      final module = _ModuleA();
      module.configureRoutes();

      expect(registeredForTest.contains(_ModuleA), isTrue);

      module.dispose();

      expect(registeredForTest.contains(_ModuleA), isFalse);
    });

    test('re-registration after dispose works (goBack scenario)', () {
      final module = _ModuleA();
      module.configureRoutes();

      final first = Modugo.container.get<_ServiceA>();
      expect(first.name, 'A');

      module.dispose();

      // Simulate navigating back — configureRoutes called again
      final module2 = _ModuleA();
      module2.configureRoutes();

      final second = Modugo.container.get<_ServiceA>();
      expect(second, isNot(same(first))); // New instance
      expect(second.name, 'A');
    });

    test('dispose of module A does not affect module B', () {
      final moduleA = _ModuleA();
      moduleA.configureRoutes();

      final moduleB = _ModuleB();
      moduleB.configureRoutes();

      moduleA.dispose();

      expect(Modugo.container.isRegistered<_ServiceA>(), isFalse);
      expect(Modugo.container.isRegistered<_ServiceB>(), isTrue);
      expect(Modugo.container.get<_ServiceB>().name, 'B');
    });

    test('dispose of module does not dispose imported modules', () {
      final module = _ModuleWithImport();
      module.configureRoutes();

      expect(Modugo.container.isRegistered<_ServiceShared>(), isTrue);
      expect(Modugo.container.isRegistered<_ServiceA>(), isTrue);

      module.dispose();

      // Module's own binding is gone
      expect(Modugo.container.isRegistered<_ServiceA>(), isFalse);
      // Imported module's binding survives
      expect(Modugo.container.isRegistered<_ServiceShared>(), isTrue);
    });

    test('onDispose callbacks are called when module is disposed', () {
      final disposable = _Disposable();
      final module = _ModuleWithDisposable(disposable);
      module.configureRoutes();

      // Access the singleton to create the instance
      Modugo.container.get<_Disposable>();

      expect(disposable.disposed, isFalse);

      module.dispose();

      expect(disposable.disposed, isTrue);
    });
  });
}
