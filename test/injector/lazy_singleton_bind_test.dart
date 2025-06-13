import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/injector.dart';

void main() {
  setUp(() => Bind.clearAll());

  group('Bind.lazySingleton', () {
    test('should not create instance until first get()', () {
      bool created = false;
      Bind.register<_LoggerService>(
        Bind.lazySingleton<_LoggerService>((i) {
          created = true;
          return _LoggerService('lazy');
        }),
      );

      final bind = Bind.getBindByType(_LoggerService) as Bind<_LoggerService>;

      expect(created, isFalse);
      expect(bind.maybeInstance, isNull);

      final logger = Injector().get<_LoggerService>();
      expect(created, isTrue);
      expect(logger.id, 'lazy');
    });

    test('should cache instance after first get()', () {
      int count = 0;
      Bind.register<_LoggerService>(
        Bind.lazySingleton<_LoggerService>(
          (i) => _LoggerService('id#${++count}'),
        ),
      );

      final first = Injector().get<_LoggerService>();
      final second = Injector().get<_LoggerService>();

      expect(first.id, 'id#1');
      expect(first, same(second));
    });

    test('should recreate after dispose', () {
      int count = 0;
      Bind.register<_LoggerService>(
        Bind.lazySingleton<_LoggerService>(
          (i) => _LoggerService('id#${++count}'),
        ),
      );

      final first = Injector().get<_LoggerService>();
      expect(first.id, 'id#1');

      Bind.disposeByType(_LoggerService);

      expect(
        () => Injector().get<_LoggerService>(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Bind not found for type _LoggerService'),
          ),
        ),
      );
    });
  });
}

final class _LoggerService {
  final String id;
  _LoggerService(this.id);
}
