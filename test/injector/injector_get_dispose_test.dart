import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

void main() {
  setUp(() => Bind.clearAll());

  group('Injector.get', () {
    test('should retrieve registered instance correctly', () {
      Bind.register<String>(Bind.singleton((i) => 'hello'));

      final result = Injector().get<String>();
      expect(result, 'hello');
    });

    test('should throw if type is not registered', () {
      expect(() => Injector().get<int>(), throwsException);
    });
  });

  group('Bind disposal', () {
    test('should dispose ChangeNotifier properly', () {
      final notifier = _DisposableNotifier();
      Bind.register<_DisposableNotifier>(
        Bind.singleton<_DisposableNotifier>((i) => notifier),
      );

      expect(notifier.disposed, isFalse);
      Bind.clearAll();
      expect(notifier.disposed, isTrue);
    });

    test('should dispose Sink properly', () {
      final sink = _DisposableSink();
      Bind.register<_DisposableSink>(
        Bind.singleton<_DisposableSink>((i) => sink),
      );

      expect(sink.closed, isFalse);
      Bind.clearAll();
      expect(sink.closed, isTrue);
    });

    test('should dispose StreamController properly', () {
      final controller = StreamController();

      Bind.register<StreamController>(
        Bind.singleton<StreamController>((i) => controller),
      );

      expect(controller.isClosed, isFalse);
      Bind.clearAll();
      expect(controller.isClosed, isTrue);
    });

    test('should dispose only the given type via disposeByType', () {
      final sink = _DisposableSink();
      final notifier = _DisposableNotifier();

      Bind.register<_DisposableSink>(
        Bind.singleton<_DisposableSink>((i) => sink),
      );
      Bind.register<_DisposableNotifier>(
        Bind.singleton<_DisposableNotifier>((i) => notifier),
      );

      Bind.disposeByType(_DisposableNotifier);

      expect(sink.closed, isFalse);
      expect(notifier.disposed, isTrue);
    });
  });
}

final class _DisposableNotifier extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

final class _DisposableSink implements Sink<void> {
  bool closed = false;

  @override
  void add(void data) {}

  @override
  void close() => closed = true;
}
