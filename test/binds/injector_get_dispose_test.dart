import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

void main() {
  setUp(() {
    Injector().clearAll();
  });

  test('isRegistered returns true if registered', () {
    Injector().addFactory<double>((_) => 3.14);

    expect(Injector().isRegistered<double>(), isTrue);
  });

  test('isRegistered returns false if not registered', () {
    expect(Injector().isRegistered<DateTime>(), isFalse);
  });

  test('should throw if type is not registered', () {
    expect(() => Injector().get<int>(), throwsException);
  });

  test('should retrieve registered instance correctly', () {
    Injector().addSingleton<String>((_) => 'modugo');

    final result = Injector().get<String>();

    expect(result, equals('modugo'));
  });

  test('disposeByType should not throw if type not registered', () {
    expect(() => Injector().disposeByType(DateTime), returnsNormally);
  });

  test('clearAll should dispose and remove all registered types', () {
    Injector()
      ..addSingleton<String>((_) => 'a')
      ..addFactory<int>((_) => 42);

    expect(Injector().isRegistered<String>(), isTrue);
    expect(Injector().isRegistered<int>(), isTrue);

    Injector().clearAll();

    expect(Injector().isRegistered<String>(), isFalse);
    expect(Injector().isRegistered<int>(), isFalse);
  });

  test('disposeByType should dispose and remove only the specified type', () {
    Injector()
      ..addSingleton<_DisposableSink>((_) => _DisposableSink())
      ..addSingleton<_DisposableNotifier>((_) => _DisposableNotifier());

    final notifier = Injector().get<_DisposableNotifier>();
    final sink = Injector().get<_DisposableSink>();

    Injector().disposeByType(_DisposableNotifier);

    expect(Injector().isRegistered<_DisposableSink>(), isTrue);
    expect(Injector().isRegistered<_DisposableNotifier>(), isFalse);

    expect(sink.closed, isFalse);
    expect(notifier.disposed, isTrue);
  });

  test('should dispose ChangeNotifier', () {
    Injector().addSingleton<_DisposableNotifier>((_) => _DisposableNotifier());

    final notifier = Injector().get<_DisposableNotifier>();

    Injector().dispose<_DisposableNotifier>();

    expect(notifier.disposed, isTrue);
  });

  test('should dispose Sink', () {
    Injector().addSingleton<_DisposableSink>((_) => _DisposableSink());

    final sink = Injector().get<_DisposableSink>();

    Injector().dispose<_DisposableSink>();

    expect(sink.closed, isTrue);
  });

  test('should dispose StreamController', () {
    Injector().addSingleton<StreamController>((_) => StreamController());

    final controller = Injector().get<StreamController>();

    Injector().dispose<StreamController>();

    expect(controller.isClosed, isTrue);
  });

  test('should dispose only the given type', () {
    Injector()
      ..addSingleton<_DisposableSink>((_) => _DisposableSink())
      ..addSingleton<_DisposableNotifier>((_) => _DisposableNotifier());

    final sink = Injector().get<_DisposableSink>();
    final notifier = Injector().get<_DisposableNotifier>();

    Injector().dispose<_DisposableNotifier>();

    expect(notifier.disposed, isTrue);
    expect(sink.closed, isFalse);
  });

  test('should not crash when disposal throws (with diagnostics on)', () {
    Injector().addSingleton<_DisposableWithError>(
      (_) => _DisposableWithError(),
    );

    expect(() => Injector().dispose<_DisposableWithError>(), returnsNormally);
  });
}

final class _DisposableWithError {
  void dispose() => throw Exception('dispose failed');
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
