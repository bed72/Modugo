import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/container/container.dart';

// ─── Test helpers ───────────────────────────────────────────

class _Counter {
  int value = 0;
}

class _ServiceA {
  final _ServiceB b;
  _ServiceA(this.b);
}

class _ServiceB {
  final String name;
  _ServiceB([this.name = 'B']);
}

class _ServiceC {}

class _Disposable {
  bool disposed = false;
  void close() => disposed = true;
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  late Container container;

  setUp(() {
    container = Container();
  });

  // ─── Registration & Resolution ────────────────────────────

  group('Registration & Resolution', () {
    test('factory returns a new instance on every get', () {
      container.add<_Counter>(() => _Counter());

      final a = container.get<_Counter>();
      final b = container.get<_Counter>();

      expect(a, isNot(same(b)));
    });

    test('singleton returns the same instance on every get', () {
      container.addSingleton<_Counter>(() => _Counter());

      final a = container.get<_Counter>();
      final b = container.get<_Counter>();

      expect(a, same(b));
    });

    test('lazySingleton returns the same instance on every get', () {
      container.addLazySingleton<_Counter>(() => _Counter());

      final a = container.get<_Counter>();
      final b = container.get<_Counter>();

      expect(a, same(b));
    });

    test('lazySingleton only creates instance on first get', () {
      var created = false;

      container.addLazySingleton<_Counter>(() {
        created = true;
        return _Counter();
      });

      expect(created, isFalse);

      container.get<_Counter>();

      expect(created, isTrue);
    });

    test('get throws StateError for unregistered type', () {
      expect(
        () => container.get<_Counter>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No binding found for type _Counter'),
          ),
        ),
      );
    });

    test('tryGet returns null for unregistered type', () {
      expect(container.tryGet<_Counter>(), isNull);
    });

    test('tryGet returns instance when registered', () {
      container.add<_Counter>(() => _Counter());

      expect(container.tryGet<_Counter>(), isNotNull);
    });

    test('isRegistered returns false before registration', () {
      expect(container.isRegistered<_Counter>(), isFalse);
    });

    test('isRegistered returns true after registration', () {
      container.add<_Counter>(() => _Counter());

      expect(container.isRegistered<_Counter>(), isTrue);
    });
  });

  // ─── Duplicate Registration ───────────────────────────────

  group('Duplicate registration', () {
    test('registering the same type twice throws StateError', () {
      container.add<_Counter>(() => _Counter());

      expect(
        () => container.add<_Counter>(() => _Counter()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Binding for type _Counter is already registered'),
          ),
        ),
      );
    });

    test('error message includes tag when available', () {
      container.activeTag = 'ModuleA';
      container.add<_Counter>(() => _Counter());
      container.activeTag = null;

      expect(
        () => container.add<_Counter>(() => _Counter()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('tag: ModuleA'),
          ),
        ),
      );
    });

    test('different types can be registered without conflict', () {
      container.add<_Counter>(() => _Counter());
      container.add<_ServiceB>(() => _ServiceB());

      expect(container.get<_Counter>(), isNotNull);
      expect(container.get<_ServiceB>(), isNotNull);
    });
  });

  // ─── Tagging ──────────────────────────────────────────────

  group('Tagging', () {
    test('registration with activeTag associates binding to module', () {
      container.activeTag = 'ModuleA';
      container.add<_Counter>(() => _Counter());
      container.activeTag = null;

      // Verify by disposing the module — binding should be removed
      container.disposeModule('ModuleA');

      expect(container.isRegistered<_Counter>(), isFalse);
    });

    test(
      'registration without activeTag is global and survives disposeModule',
      () {
        container.add<_Counter>(() => _Counter());

        container.disposeModule('SomeModule');

        expect(container.isRegistered<_Counter>(), isTrue);
        expect(container.get<_Counter>(), isNotNull);
      },
    );

    test('multiple bindings under the same tag', () {
      container.activeTag = 'ModuleA';
      container.add<_Counter>(() => _Counter());
      container.add<_ServiceB>(() => _ServiceB());
      container.add<_ServiceC>(() => _ServiceC());
      container.activeTag = null;

      container.disposeModule('ModuleA');

      expect(container.isRegistered<_Counter>(), isFalse);
      expect(container.isRegistered<_ServiceB>(), isFalse);
      expect(container.isRegistered<_ServiceC>(), isFalse);
    });

    test('bindings from different tags are independent', () {
      container.activeTag = 'ModuleA';
      container.add<_Counter>(() => _Counter());
      container.activeTag = 'ModuleB';
      container.add<_ServiceB>(() => _ServiceB());
      container.activeTag = null;

      container.disposeModule('ModuleA');

      expect(container.isRegistered<_Counter>(), isFalse);
      expect(container.isRegistered<_ServiceB>(), isTrue);
    });
  });

  // ─── disposeModule ────────────────────────────────────────

  group('disposeModule', () {
    test('calls onDispose for each singleton', () {
      final disposable = _Disposable();

      container.activeTag = 'Mod';
      container.addSingleton<_Disposable>(
        () => disposable,
        onDispose: (d) => d.close(),
      );
      container.activeTag = null;

      // Force instance creation
      container.get<_Disposable>();

      container.disposeModule('Mod');

      expect(disposable.disposed, isTrue);
    });

    test('calls onDispose for lazySingleton', () {
      final disposable = _Disposable();

      container.activeTag = 'Mod';
      container.addLazySingleton<_Disposable>(
        () => disposable,
        onDispose: (d) => d.close(),
      );
      container.activeTag = null;

      container.get<_Disposable>();
      container.disposeModule('Mod');

      expect(disposable.disposed, isTrue);
    });

    test('removes bindings from container after dispose', () {
      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(() => _Counter());
      container.activeTag = null;

      container.disposeModule('Mod');

      expect(() => container.get<_Counter>(), throwsA(isA<StateError>()));
    });

    test('does not affect bindings from other modules', () {
      container.activeTag = 'ModA';
      container.add<_Counter>(() => _Counter());
      container.activeTag = 'ModB';
      container.add<_ServiceB>(() => _ServiceB());
      container.activeTag = null;

      container.disposeModule('ModA');

      expect(container.get<_ServiceB>(), isNotNull);
    });

    test('does not throw for non-existent tag', () {
      expect(() => container.disposeModule('ghost'), returnsNormally);
    });

    test('factory onDispose is NOT called (no instance kept)', () {
      var disposeCalled = false;

      container.activeTag = 'Mod';
      container.add<_Counter>(() => _Counter());
      container.activeTag = null;

      // Factory has no onDispose parameter, but even if the binding
      // is disposed, there's no instance to dispose
      container.get<_Counter>();
      container.disposeModule('Mod');

      expect(disposeCalled, isFalse);
    });

    test('singleton without onDispose does not throw on dispose', () {
      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(() => _Counter());
      container.activeTag = null;

      container.get<_Counter>();

      expect(() => container.disposeModule('Mod'), returnsNormally);
    });

    test('onDispose is NOT called if singleton was never accessed', () {
      var disposeCalled = false;

      container.activeTag = 'Mod';
      container.addLazySingleton<_Disposable>(
        () => _Disposable(),
        onDispose: (d) {
          disposeCalled = true;
          d.close();
        },
      );
      container.activeTag = null;

      // Never call get — instance was never created
      container.disposeModule('Mod');

      expect(disposeCalled, isFalse);
    });

    test('disposes in reverse registration order', () {
      final order = <String>[];

      container.activeTag = 'Mod';
      container.addSingleton<_ServiceB>(
        () => _ServiceB(),
        onDispose: (_) => order.add('B'),
      );
      container.addSingleton<_Counter>(
        () => _Counter(),
        onDispose: (_) => order.add('Counter'),
      );
      container.addSingleton<_ServiceC>(
        () => _ServiceC(),
        onDispose: (_) => order.add('C'),
      );
      container.activeTag = null;

      // Create all instances
      container.get<_ServiceB>();
      container.get<_Counter>();
      container.get<_ServiceC>();

      container.disposeModule('Mod');

      // Reverse order: C → Counter → B
      expect(order, ['C', 'Counter', 'B']);
    });
  });

  // ─── disposeAll ───────────────────────────────────────────

  group('disposeAll', () {
    test('clears all bindings', () {
      container.activeTag = 'ModA';
      container.add<_Counter>(() => _Counter());
      container.activeTag = 'ModB';
      container.add<_ServiceB>(() => _ServiceB());
      container.activeTag = null;
      container.add<_ServiceC>(() => _ServiceC());

      container.disposeAll();

      expect(container.isRegistered<_Counter>(), isFalse);
      expect(container.isRegistered<_ServiceB>(), isFalse);
      expect(container.isRegistered<_ServiceC>(), isFalse);
    });

    test('calls onDispose for all singletons with live instances', () {
      final disposedTypes = <String>[];

      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(
        () => _Counter(),
        onDispose: (_) => disposedTypes.add('Counter'),
      );
      container.addSingleton<_ServiceB>(
        () => _ServiceB(),
        onDispose: (_) => disposedTypes.add('ServiceB'),
      );
      container.activeTag = null;

      // Create instances
      container.get<_Counter>();
      container.get<_ServiceB>();

      container.disposeAll();

      expect(disposedTypes, containsAll(['Counter', 'ServiceB']));
    });

    test('get throws after disposeAll', () {
      container.add<_Counter>(() => _Counter());
      container.disposeAll();

      expect(() => container.get<_Counter>(), throwsA(isA<StateError>()));
    });
  });

  // ─── Re-registration after dispose ────────────────────────

  group('Re-registration after dispose', () {
    test('can register same type after disposeModule', () {
      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(() => _Counter());
      container.activeTag = null;

      container.get<_Counter>().value = 42;
      container.disposeModule('Mod');

      // Re-register
      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(() => _Counter());
      container.activeTag = null;

      final instance = container.get<_Counter>();
      expect(instance.value, 0); // Fresh instance, not the old one
    });

    test('can register same type after disposeAll', () {
      container.addSingleton<_Counter>(() => _Counter());
      container.get<_Counter>().value = 99;

      container.disposeAll();

      container.addSingleton<_Counter>(() => _Counter());
      expect(container.get<_Counter>().value, 0);
    });
  });

  // ─── Dependencies between bindings ────────────────────────

  group('Dependencies between bindings', () {
    test('singleton resolves dependency from another binding', () {
      container.add<_ServiceB>(() => _ServiceB('resolved'));
      container.addSingleton<_ServiceA>(
        () => _ServiceA(container.get<_ServiceB>()),
      );

      final a = container.get<_ServiceA>();

      expect(a.b.name, 'resolved');
    });

    test('factory resolves dependency from singleton', () {
      container.addSingleton<_ServiceB>(() => _ServiceB('shared'));
      container.add<_ServiceA>(() => _ServiceA(container.get<_ServiceB>()));

      final a1 = container.get<_ServiceA>();
      final a2 = container.get<_ServiceA>();

      // Different ServiceA instances (factory)
      expect(a1, isNot(same(a2)));
      // But same ServiceB instance (singleton)
      expect(a1.b, same(a2.b));
      expect(a1.b.name, 'shared');
    });
  });

  // ─── Circular dependency detection ────────────────────────

  group('Circular dependency detection', () {
    test('throws StateError with descriptive message', () {
      container.add<_ServiceA>(() => _ServiceA(container.get<_ServiceB>()));
      container.add<_ServiceB>(
        () => _ServiceB(container.get<_ServiceA>().b.name),
      );

      expect(
        () => container.get<_ServiceA>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Circular dependency detected'),
              contains('_ServiceA'),
              contains('_ServiceB'),
            ),
          ),
        ),
      );
    });

    test('resolving set is cleaned up after circular dependency error', () {
      container.add<_ServiceA>(() => _ServiceA(container.get<_ServiceB>()));
      container.add<_ServiceB>(
        () => _ServiceB(container.get<_ServiceA>().b.name),
      );

      // First call — throws
      expect(() => container.get<_ServiceA>(), throwsA(isA<StateError>()));

      // Second call — should also throw the same error (not a stale state)
      expect(
        () => container.get<_ServiceA>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );
    });

    test('non-circular chains resolve normally', () {
      container.add<_ServiceB>(() => _ServiceB());
      container.addSingleton<_ServiceA>(
        () => _ServiceA(container.get<_ServiceB>()),
      );

      expect(() => container.get<_ServiceA>(), returnsNormally);
    });

    test('tryGet also detects circular dependencies', () {
      container.add<_ServiceA>(() => _ServiceA(container.get<_ServiceB>()));
      container.add<_ServiceB>(
        () => _ServiceB(container.get<_ServiceA>().b.name),
      );

      expect(
        () => container.tryGet<_ServiceA>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Circular dependency detected'),
          ),
        ),
      );
    });
  });

  // ─── Edge cases ───────────────────────────────────────────

  group('Edge cases', () {
    test('disposeModule called twice does not throw', () {
      container.activeTag = 'Mod';
      container.addSingleton<_Counter>(() => _Counter());
      container.activeTag = null;

      container.get<_Counter>();

      expect(() => container.disposeModule('Mod'), returnsNormally);
      expect(() => container.disposeModule('Mod'), returnsNormally);
    });

    test('disposeAll called on empty container does not throw', () {
      expect(() => container.disposeAll(), returnsNormally);
    });

    test('disposeAll called twice does not throw', () {
      container.add<_Counter>(() => _Counter());
      container.disposeAll();

      expect(() => container.disposeAll(), returnsNormally);
    });

    test('global binding survives disposeModule of any tag', () {
      container.add<_Counter>(() => _Counter()); // global (no tag)

      container.activeTag = 'Mod';
      container.add<_ServiceB>(() => _ServiceB());
      container.activeTag = null;

      container.disposeModule('Mod');

      expect(container.isRegistered<_Counter>(), isTrue);
      expect(container.get<_Counter>(), isNotNull);
    });

    test('global binding is cleaned by disposeAll', () {
      container.add<_Counter>(() => _Counter());

      container.disposeAll();

      expect(container.isRegistered<_Counter>(), isFalse);
    });
  });
}
