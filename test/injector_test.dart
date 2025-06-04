import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

import 'mocks/services_mock.dart';

void main() {
  setUp(() {
    Bind.disposeByType(ServiceMock);
    Bind.disposeByType(OtherServiceMock);
  });

  test('should return the same instance', () {
    Bind.register<OtherServiceMock>(
      Bind.singleton((_) => OtherServiceMock(id: 1)),
    );

    final a = Bind.get<OtherServiceMock>();
    final b = Bind.get<OtherServiceMock>();

    expect(identical(a, b), true);
    expect(a.id, equals(1));
  });

  test('should create instance only on first get', () {
    bool created = false;

    Bind.register<OtherServiceMock>(
      Bind.lazySingleton((_) {
        created = true;
        return OtherServiceMock(id: 2);
      }),
    );

    expect(created, isFalse);

    final a = Bind.get<OtherServiceMock>();
    expect(created, isTrue);
    final b = Bind.get<OtherServiceMock>();

    expect(identical(a, b), isTrue);
    expect(a.id, equals(2));
  });

  test('should create new instance on every get', () {
    Bind.register<OtherServiceMock>(
      Bind.factory((_) => OtherServiceMock(id: 3)),
    );

    final a = Bind.get<OtherServiceMock>();
    final b = Bind.get<OtherServiceMock>();

    expect(identical(a, b), isFalse);
    expect(a.id, equals(3));
    expect(b.id, equals(3));
  });

  test('should resolve using Injector.get()', () {
    Bind.register<ServiceMock>(Bind.singleton((_) => ServiceMock()));

    final injector = Injector();
    final service = injector.get<ServiceMock>();
    service.value++;

    final again = injector.get<ServiceMock>();
    expect(again.value, equals(1));
  });

  test('should remove bind and throw on next get', () {
    Bind.register<OtherServiceMock>(Bind.singleton((_) => OtherServiceMock()));

    Bind.get<OtherServiceMock>();

    Bind.disposeByType(OtherServiceMock);

    expect(() => Bind.get<OtherServiceMock>(), throwsException);
  });

  test('Should throw if bind not found', () {
    expect(() => Bind.get<String>(), throwsException);
  });

  test('singleton not lazy should instantiate immediately', () {
    Bind.register<OtherServiceMock>(
      Bind((_) => OtherServiceMock(), isLazy: false, isSingleton: true),
    );

    expect(Bind.get<OtherServiceMock>(), isA<OtherServiceMock>());
  });

  test('registering twice should overwrite previous bind', () {
    Bind.register<OtherServiceMock>(
      Bind.singleton((_) => OtherServiceMock(id: 1)),
    );

    Bind.register<OtherServiceMock>(
      Bind.singleton((_) => OtherServiceMock(id: 2)),
    );

    final instance = Bind.get<OtherServiceMock>();
    expect(instance.id, equals(2));
  });

  test('clearAll should dispose all and clear binds', () {
    Bind.register<OtherServiceMock>(
      Bind.singleton((_) => OtherServiceMock(id: 1)),
    );
    Bind.register<ServiceMock>(Bind.singleton((_) => ServiceMock()));

    expect(Bind.get<OtherServiceMock>(), isNotNull);
    expect(Bind.get<ServiceMock>(), isNotNull);

    Bind.clearAll();

    expect(() => Bind.get<OtherServiceMock>(), throwsException);
    expect(() => Bind.get<ServiceMock>(), throwsException);
  });

  test('disposeInstance should close StreamController', () {
    final controller = StreamController();

    Bind.register<StreamController>(Bind.singleton((_) => controller));

    Bind.get<StreamController>();

    Bind.disposeByType(StreamController);

    expect(controller.isClosed, isTrue);
  });

  test('dispose does not crash if no cleanup method exists', () {
    Bind.register<NoDisposeMock>(Bind.singleton((_) => NoDisposeMock()));

    Bind.get<NoDisposeMock>();

    expect(() => Bind.disposeByType(NoDisposeMock), returnsNormally);
  });

  test('getBindByType returns correct bind', () {
    final bind = Bind.singleton((_) => OtherServiceMock());
    Bind.register<OtherServiceMock>(bind);

    final retrieved = Bind.getBindByType(OtherServiceMock);
    expect(retrieved, same(bind));
  });

  test('isRegistered returns true if bind is registered', () {
    Bind.register<ServiceMock>(Bind.singleton((_) => ServiceMock()));

    final isRegistered = Bind.isRegistered<ServiceMock>();
    expect(isRegistered, isTrue);
  });

  test('isRegistered returns false if bind is not registered', () {
    final isRegistered = Bind.isRegistered<String>();
    expect(isRegistered, isFalse);
  });
}
