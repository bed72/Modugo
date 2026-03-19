import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Documents the `unregister()` pattern for individual dependency removal.
///
/// `unregister<T>()` removes a single registration. It accepts an optional
/// `disposingFunction` that overrides any `dispose:` callback provided at
/// registration time.
void main() {
  late GetIt i;

  setUp(() {
    i = GetIt.asNewInstance();
  });

  tearDown(() async {
    await i.reset();
  });

  group('unregister with disposingFunction', () {
    test('disposingFunction is called on unregister', () {
      bool functionCalled = false;

      i.registerSingleton<_Service>(_Service());

      i.unregister<_Service>(disposingFunction: (_) => functionCalled = true);

      expect(functionCalled, isTrue);
      expect(i.isRegistered<_Service>(), isFalse);
    });

    test('disposingFunction overrides original dispose callback', () {
      final calls = <String>[];

      i.registerSingleton<_Service>(
        _Service(),
        dispose: (_) => calls.add('original'),
      );

      i.unregister<_Service>(disposingFunction: (_) => calls.add('override'));

      // Only the override is called, not the original
      expect(calls, ['override']);
    });

    test(
      'unregister without disposingFunction calls original dispose',
      () async {
        bool originalCalled = false;

        i.registerSingleton<_Service>(
          _Service(),
          dispose: (_) => originalCalled = true,
        );

        i.unregister<_Service>();

        expect(originalCalled, isTrue);
      },
    );
  });

  group('resetLazySingleton', () {
    test('resetLazySingleton disposes and allows recreation', () {
      int createCount = 0;
      bool disposed = false;

      i.registerLazySingleton<_Service>(() {
        createCount++;
        return _Service();
      }, dispose: (_) => disposed = true);

      // First access — creates instance
      i.get<_Service>();
      expect(createCount, 1);

      // Reset — disposes current instance
      i.resetLazySingleton<_Service>();
      expect(disposed, isTrue);

      // Next access — creates new instance
      i.get<_Service>();
      expect(createCount, 2);
    });
  });
}

class _Service {}
