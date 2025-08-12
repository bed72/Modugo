import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/binds/singleton_bind.dart';

void main() {
  test('should create instance eagerly and always return the same', () async {
    final bind = SingletonBind<_Service>((_) => _Service(42));
    final first = await bind.get(Injector());
    final second = await bind.get(Injector());

    expect(first.value, 42);
    expect(identical(first, second), isTrue);
  });

  test('dispose() clears the instance', () {
    final bind = SingletonBind<_Service>((_) => _Service(1));
    final instanceBefore = bind.get(Injector());

    bind.dispose();
    final instanceAfter = bind.get(Injector());

    expect(identical(instanceBefore, instanceAfter), isFalse);
  });

  test('dispose() calls dispose() on ChangeNotifier', () async {
    final bind = SingletonBind<_Disposable>((_) => _Disposable());
    final instance = await bind.get(Injector());

    expect(instance.disposed, isFalse);
    bind.dispose();
    expect(instance.disposed, isTrue);
  });

  test('dispose() closes Sink', () async {
    final bind = SingletonBind<_Sink>((_) => _Sink());
    final sink = await bind.get(Injector());

    expect(sink.closed, isFalse);
    bind.dispose();
    expect(sink.closed, isTrue);
  });

  test('dispose() closes StreamController', () async {
    final bind = SingletonBind<StreamController<String>>(
      (_) => StreamController<String>(),
    );
    final controller = await bind.get(Injector());

    expect(controller.isClosed, isFalse);
    bind.dispose();
    expect(controller.isClosed, isTrue);
  });

  test('dispose() can be called multiple times without error', () {
    final bind = SingletonBind<_Service>((_) => _Service(1));
    bind.dispose();
    expect(() => bind.dispose(), returnsNormally);
  });

  test('dispose logs error when dispose fails and diagnostics enabled', () {
    final bind = SingletonBind<_ThrowingDisposable>(
      (_) => _ThrowingDisposable(),
    );
    bind.get(Injector());

    expect(() => bind.dispose(), returnsNormally);
  });

  test('dispose is safe when instance is null (never initialized)', () {
    final bind = SingletonBind<_Service>((_) => _Service(1));

    expect(() => bind.dispose(), returnsNormally);
  });
}

final class _Service {
  final int value;
  _Service(this.value);
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
