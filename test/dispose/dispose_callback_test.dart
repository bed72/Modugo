import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Documents the `dispose:` callback pattern available in GetIt.
///
/// The `dispose:` parameter can be passed to `registerSingleton` and
/// `registerLazySingleton`. It is called when the instance is removed via
/// `unregister()`, `reset()`, or `popScope()` — never automatically.
///
/// This is equivalent to Koin's `onClose` callback.
void main() {
  late GetIt i;

  setUp(() {
    i = GetIt.asNewInstance();
  });

  tearDown(() async {
    await i.reset();
  });

  group('dispose: callback on registerSingleton', () {
    test('dispose callback is called on unregister()', () {
      bool disposed = false;

      i.registerSingleton<_Service>(
        _Service(),
        dispose: (service) => disposed = true,
      );

      expect(disposed, isFalse);

      i.unregister<_Service>();

      expect(disposed, isTrue);
    });

    test('dispose callback is called on reset()', () async {
      bool disposed = false;

      i.registerSingleton<_Service>(
        _Service(),
        dispose: (service) => disposed = true,
      );

      expect(disposed, isFalse);

      await i.reset();

      expect(disposed, isTrue);
    });

    test('dispose callback is NOT called without explicit invocation', () {
      bool disposed = false;

      i.registerSingleton<_Service>(
        _Service(),
        dispose: (service) => disposed = true,
      );

      // Access the service, use it — dispose is never called automatically
      final _ = i.get<_Service>();

      expect(disposed, isFalse);
    });
  });

  group('dispose: callback on registerLazySingleton', () {
    test('dispose callback is called on unregister()', () {
      bool disposed = false;

      i.registerLazySingleton<_Service>(
        () => _Service(),
        dispose: (service) => disposed = true,
      );

      // Force creation
      final _ = i.get<_Service>();

      i.unregister<_Service>();

      expect(disposed, isTrue);
    });

    test('dispose callback is called on reset()', () async {
      bool disposed = false;

      i.registerLazySingleton<_Service>(
        () => _Service(),
        dispose: (service) => disposed = true,
      );

      // Force creation
      final _ = i.get<_Service>();

      await i.reset();

      expect(disposed, isTrue);
    });

    test('dispose callback receives the actual instance', () async {
      _Service? disposedInstance;

      final original = _Service();

      i.registerSingleton<_Service>(
        original,
        dispose: (service) => disposedInstance = service,
      );

      await i.reset();

      expect(disposedInstance, same(original));
    });
  });

  group('multiple dispose callbacks on reset', () {
    test('all dispose callbacks are called on reset()', () async {
      final disposed = <String>[];

      i.registerSingleton<_ServiceA>(
        _ServiceA(),
        dispose: (_) => disposed.add('A'),
      );
      i.registerSingleton<_ServiceB>(
        _ServiceB(),
        dispose: (_) => disposed.add('B'),
      );

      await i.reset();

      expect(disposed, containsAll(['A', 'B']));
    });
  });
}

class _Service {}

class _ServiceA {}

class _ServiceB {}
