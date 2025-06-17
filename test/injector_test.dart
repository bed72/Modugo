import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

void main() {
  setUp(() => Injector().clearAll());

  test('addSingleton should register and return same instance', () {
    Injector().addSingleton<_Service>((_) => _Service(1));

    final s1 = Injector().get<_Service>();
    final s2 = Injector().get<_Service>();

    expect(identical(s1, s2), isTrue);
    expect(s1.value, 1);
  });

  test('addLazySingleton should return same instance after first get', () {
    int counter = 0;
    Injector().addLazySingleton<_Service>((_) => _Service(++counter));

    final first = Injector().get<_Service>();
    final second = Injector().get<_Service>();

    expect(first.value, 1);
    expect(identical(first, second), isTrue);
  });

  test('addFactory should return new instance every time', () {
    int counter = 0;
    Injector().addFactory<_Service>((_) => _Service(++counter));

    final one = Injector().get<_Service>();
    final two = Injector().get<_Service>();

    expect(one.value, 1);
    expect(two.value, 2);
    expect(identical(one, two), isFalse);
  });

  test('isRegistered returns true for registered type', () {
    Injector().addSingleton<String>((_) => 'ok');

    expect(Injector().isRegistered<String>(), isTrue);
  });

  test('isRegistered returns false if not registered', () {
    expect(Injector().isRegistered<double>(), isFalse);
  });

  test('get throws if type is not registered', () {
    expect(() => Injector().get<DateTime>(), throwsException);
  });

  test('dispose<T>() removes only the given type', () {
    Injector()
      ..addSingleton<String>((_) => 'modugo')
      ..addFactory<_Service>((_) => _Service(0));

    Injector().dispose<String>();

    expect(Injector().isRegistered<String>(), isFalse);
    expect(Injector().isRegistered<_Service>(), isTrue);
  });

  test('disposeByType removes the given type', () {
    Injector()
      ..addSingleton<int>((_) => 42)
      ..addSingleton<_Service>((_) => _Service(5));

    Injector().disposeByType(int);

    expect(Injector().isRegistered<int>(), isFalse);
    expect(Injector().isRegistered<_Service>(), isTrue);
  });

  test('clearAll removes all registered types', () {
    Injector()
      ..addSingleton<String>((_) => 'clean')
      ..addFactory<_Service>((_) => _Service(9));

    Injector().clearAll();

    expect(Injector().isRegistered<String>(), isFalse);
    expect(Injector().isRegistered<_Service>(), isFalse);
  });
}

final class _Service {
  final int value;
  _Service(this.value);
}
