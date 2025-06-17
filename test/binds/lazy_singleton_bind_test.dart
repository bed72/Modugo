import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/binds/lazy_singleton_bind.dart';

void main() {
  late LazySingletonBind<_Disposable> bind;

  setUp(() {
    bind = LazySingletonBind((_) => _Disposable());
  });

  test('get() returns same instance across calls', () {
    final first = bind.get(Injector());
    final second = bind.get(Injector());

    expect(identical(first, second), isTrue);
  });

  test('dispose() clears instance and allows re-creation', () {
    final original = bind.get(Injector());

    bind.dispose();
    final recreated = bind.get(Injector());

    expect(identical(original, recreated), isFalse);
  });

  test('dispose() calls dispose() on ChangeNotifier', () {
    final instance = bind.get(Injector());

    expect(instance.disposed, isFalse);

    bind.dispose();

    expect(instance.disposed, isTrue);
  });

  test('dispose() closes a StreamController', () {
    final bind = LazySingletonBind((_) => StreamController<String>());
    final controller = bind.get(Injector());

    expect(controller.isClosed, isFalse);

    bind.dispose();

    expect(controller.isClosed, isTrue);
  });

  test('dispose() closes a Sink', () {
    final sink = _Sink();
    final bind = LazySingletonBind((_) => sink);

    final instance = bind.get(Injector());
    expect(instance.closed, isFalse);

    bind.dispose();

    expect(instance.closed, isTrue);
  });
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
