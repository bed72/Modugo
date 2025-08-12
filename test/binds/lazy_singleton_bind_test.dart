import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/binds/lazy_singleton_bind.dart';

void main() {
  late LazySingletonBind<_Disposable> bind;

  setUp(() {
    bind = LazySingletonBind<_Disposable>((_) => _Disposable());
  });

  test('get() returns same instance across calls', () async {
    final first = await bind.get(Injector());
    final second = await bind.get(Injector());

    expect(identical(first, second), isTrue);
  });

  test('dispose() clears instance and allows re-creation', () {
    final original = bind.get(Injector());

    bind.dispose();
    final recreated = bind.get(Injector());

    expect(identical(original, recreated), isFalse);
  });

  test('dispose() calls dispose() on ChangeNotifier', () async {
    final instance = await bind.get(Injector());

    expect(instance.disposed, isFalse);

    bind.dispose();

    expect(instance.disposed, isTrue);
  });

  test('dispose() closes a StreamController', () async {
    final bind = LazySingletonBind<StreamController<String>>(
      (_) => StreamController<String>(),
    );
    final controller = await bind.get(Injector());

    expect(controller.isClosed, isFalse);

    bind.dispose();

    expect(controller.isClosed, isTrue);
  });

  test('dispose() closes a Sink', () async {
    final sink = _Sink();
    final bind = LazySingletonBind((_) => sink);

    final instance = await bind.get(Injector());
    expect(instance.closed, isFalse);

    bind.dispose();

    expect(instance.closed, isTrue);
  });

  test('dispose() is safe when instance is null (never created)', () {
    final bind = LazySingletonBind<_Disposable>((_) => _Disposable());

    expect(() => bind.dispose(), returnsNormally);
  });

  test('dispose() logs error when dispose throws and diagnostics enabled', () {
    final bind = LazySingletonBind<_ThrowingDisposable>(
      (_) => _ThrowingDisposable(),
    );
    bind.get(Injector());

    expect(() => bind.dispose(), returnsNormally);
  });
}

final class _ThrowingDisposable {
  void dispose() => throw Exception('dispose error');
}

final class _Disposable extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

final class _Sink implements Sink {
  bool closed = false;

  @override
  void add(_) {}

  @override
  void close() {
    closed = true;
  }
}
