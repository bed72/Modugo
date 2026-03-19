import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Documents the `Disposable` interface pattern from GetIt.
///
/// When a registered instance implements `Disposable`, GetIt automatically
/// calls `onDispose()` during `reset()` or `popScope()` — no need to pass
/// a `dispose:` callback at registration time.
///
/// This is useful for services that know how to clean up after themselves.
void main() {
  late GetIt i;

  setUp(() {
    i = GetIt.asNewInstance();
  });

  tearDown(() async {
    await i.reset();
  });

  group('Disposable interface', () {
    test('onDispose() is called automatically on reset()', () async {
      final service = _DisposableService();

      i.registerSingleton<_DisposableService>(service);

      expect(service.disposed, isFalse);

      await i.reset();

      expect(service.disposed, isTrue);
    });

    test('onDispose() is called on popScope() for scoped instances', () async {
      // Register in base scope
      i.registerSingleton<_Counter>(_Counter());

      // Push a new scope and register a Disposable there
      i.pushNewScope(scopeName: 'feature');
      final service = _DisposableService();
      i.registerSingleton<_DisposableService>(service);

      expect(service.disposed, isFalse);

      await i.popScope();

      expect(service.disposed, isTrue);

      // Base scope service is still available
      expect(i.isRegistered<_Counter>(), isTrue);
    });

    test(
      'onDispose() is called even without explicit dispose: callback',
      () async {
        final service = _DisposableService();

        // No dispose: parameter — GetIt detects the Disposable interface
        i.registerSingleton<_DisposableService>(service);

        await i.reset();

        expect(service.disposed, isTrue);
      },
    );

    test('async onDispose() is awaited on reset()', () async {
      final service = _AsyncDisposableService();

      i.registerSingleton<_AsyncDisposableService>(service);

      await i.reset();

      expect(service.disposed, isTrue);
    });
  });
}

class _DisposableService implements Disposable {
  bool disposed = false;

  @override
  FutureOr onDispose() {
    disposed = true;
  }
}

class _AsyncDisposableService implements Disposable {
  bool disposed = false;

  @override
  Future<void> onDispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    disposed = true;
  }
}

class _Counter {}
