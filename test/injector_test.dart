import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

import 'mocks/services_mock.dart';

void main() {
  setUp(() {
    Bind.disposeByType(ExampleServiceMock);
    Bind.disposeByType(CounterServiceMock);
  });

  test('should return the same instance', () {
    Bind.register<ExampleServiceMock>(
      Bind.singleton((_) => ExampleServiceMock(id: 1)),
    );

    final a = Bind.get<ExampleServiceMock>();
    final b = Bind.get<ExampleServiceMock>();

    expect(identical(a, b), true);
    expect(a.id, equals(1));
  });

  test('should create instance only on first get', () {
    var created = false;

    Bind.register<ExampleServiceMock>(
      Bind.lazySingleton((_) {
        created = true;
        return ExampleServiceMock(id: 2);
      }),
    );

    expect(created, isFalse);

    final a = Bind.get<ExampleServiceMock>();
    expect(created, isTrue);
    final b = Bind.get<ExampleServiceMock>();

    expect(identical(a, b), isTrue);
    expect(a.id, equals(2));
  });

  test('should create new instance on every get', () {
    Bind.register<ExampleServiceMock>(
      Bind.factory((_) => ExampleServiceMock(id: 3)),
    );

    final a = Bind.get<ExampleServiceMock>();
    final b = Bind.get<ExampleServiceMock>();

    expect(identical(a, b), isFalse);
    expect(a.id, equals(3));
    expect(b.id, equals(3));
  });

  test('should resolve using Injector.get()', () {
    Bind.register<CounterServiceMock>(
      Bind.singleton((_) => CounterServiceMock()),
    );

    final injector = Injector();
    final service = injector.get<CounterServiceMock>();
    service.value++;

    final again = injector.get<CounterServiceMock>();
    expect(again.value, equals(1));
  });

  test('should remove bind and throw on next get', () {
    Bind.register<ExampleServiceMock>(
      Bind.singleton((_) => ExampleServiceMock()),
    );

    Bind.get<ExampleServiceMock>();

    Bind.dispose<ExampleServiceMock>();

    expect(() => Bind.get<ExampleServiceMock>(), throwsException);
  });

  test('Should throw if bind not found', () {
    expect(() => Bind.get<String>(), throwsException);
  });

  test('singleton not lazy should instantiate immediately', () {
    Bind.register<ExampleServiceMock>(
      Bind((_) => ExampleServiceMock(), isLazy: false, isSingleton: true),
    );

    expect(Bind.get<ExampleServiceMock>(), isA<ExampleServiceMock>());
  });

  test('registering twice should overwrite previous bind', () {
    Bind.register<ExampleServiceMock>(
      Bind.singleton((_) => ExampleServiceMock(id: 1)),
    );

    Bind.register<ExampleServiceMock>(
      Bind.singleton((_) => ExampleServiceMock(id: 2)),
    );

    final instance = Bind.get<ExampleServiceMock>();
    expect(instance.id, equals(2));
  });
}
