import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

void main() {
  setUp(() => Bind.clearAll());

  group('Bind.singleton', () {
    test('should create and cache instance immediately when registered', () {
      final instance = _CounterService();
      Bind.register<_CounterService>(
        Bind.singleton<_CounterService>((i) => instance),
      );

      final bind = Bind.getBindByType(_CounterService) as Bind<_CounterService>;

      expect(bind.isSingleton, isTrue);
      expect(bind.isLazy, isFalse);
      expect(bind.maybeInstance, same(instance));
      expect(Injector().get<_CounterService>(), same(instance));
    });

    test('should return the same instance on multiple gets', () {
      int initCount = 0;
      Bind.register<_CounterService>(
        Bind.singleton<_CounterService>((i) {
          initCount++;
          return _CounterService();
        }),
      );

      final first = Injector().get<_CounterService>();
      final second = Injector().get<_CounterService>();

      expect(first, same(second));
      expect(initCount, equals(1));
    });

    test('should dispose correctly via clearAll', () {
      Bind.register<_CounterService>(
        Bind.singleton<_CounterService>((i) => _CounterService()),
      );

      final before = Injector().get<_CounterService>();
      Bind.clearAll();

      Bind.register<_CounterService>(
        Bind.singleton<_CounterService>((i) => _CounterService()),
      );
      final after = Injector().get<_CounterService>();

      expect(before, isNot(same(after)));
    });
  });
}

final class _CounterService {
  int value = 0;
}
