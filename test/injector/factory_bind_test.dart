import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/injector.dart';

void main() {
  setUp(() => Bind.clearAll());

  group('Bind.factory', () {
    test('should create a new instance every time', () {
      Bind.register<_CounterService>(
        Bind.factory<_CounterService>((i) => _CounterService()),
      );

      final first = Injector().get<_CounterService>();
      final second = Injector().get<_CounterService>();

      expect(first, isNot(same(second)));
      expect(first.runtimeType, _CounterService);
      expect(second.runtimeType, _CounterService);
    });

    test('should not cache the instance', () {
      Bind.register<_CounterService>(
        Bind.factory<_CounterService>((i) => _CounterService()),
      );

      final bind = Bind.getBindByType(_CounterService) as Bind<_CounterService>;

      expect(bind.isLazy, isFalse);
      expect(bind.isSingleton, isFalse);
      expect(bind.maybeInstance, isNull);

      final one = bind.instance;
      final two = bind.instance;

      expect(one, isNot(same(two)));
    });

    test('should throw when not registered', () {
      expect(() => Injector().get<_CounterService>(), throwsException);
    });
  });
}

final class _CounterService {
  int value = 0;
}
