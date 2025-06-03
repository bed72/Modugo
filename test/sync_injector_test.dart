import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injectors/injector.dart';
import 'package:modugo/src/injectors/sync_injector.dart';

import 'mocks/services_mock.dart';

void main() {
  setUp(() {
    SyncBind.disposeByType(SyncOtherServiceMock);
    SyncBind.disposeByType(SyncServiceMock);
  });

  test('should return the same instance', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.singleton((_) => SyncOtherServiceMock(id: 1)),
    );

    final a = SyncBind.get<SyncOtherServiceMock>();
    final b = SyncBind.get<SyncOtherServiceMock>();

    expect(identical(a, b), true);
    expect(a.id, equals(1));
  });

  test('should create instance only on first get', () {
    bool created = false;

    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.lazySingleton((_) {
        created = true;
        return SyncOtherServiceMock(id: 2);
      }),
    );

    expect(created, isFalse);

    final a = SyncBind.get<SyncOtherServiceMock>();
    expect(created, isTrue);
    final b = SyncBind.get<SyncOtherServiceMock>();

    expect(identical(a, b), isTrue);
    expect(a.id, equals(2));
  });

  test('should create new instance on every get', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.factory((_) => SyncOtherServiceMock(id: 3)),
    );

    final a = SyncBind.get<SyncOtherServiceMock>();
    final b = SyncBind.get<SyncOtherServiceMock>();

    expect(identical(a, b), isFalse);
    expect(a.id, equals(3));
    expect(b.id, equals(3));
  });

  test('should resolve using Injector.get()', () {
    SyncBind.register<SyncServiceMock>(
      SyncBind.singleton((_) => SyncServiceMock()),
    );

    final injector = Injector();
    final service = injector.getSync<SyncServiceMock>();
    service.value++;

    final again = injector.getSync<SyncServiceMock>();
    expect(again.value, equals(1));
  });

  test('should remove bind and throw on next get', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.singleton((_) => SyncOtherServiceMock()),
    );

    SyncBind.get<SyncOtherServiceMock>();

    SyncBind.disposeByType(SyncOtherServiceMock);

    expect(() => SyncBind.get<SyncOtherServiceMock>(), throwsException);
  });

  test('Should throw if bind not found', () {
    expect(() => SyncBind.get<String>(), throwsException);
  });

  test('singleton not lazy should instantiate immediately', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind((_) => SyncOtherServiceMock(), isLazy: false, isSingleton: true),
    );

    expect(SyncBind.get<SyncOtherServiceMock>(), isA<SyncOtherServiceMock>());
  });

  test('registering twice should overwrite previous bind', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.singleton((_) => SyncOtherServiceMock(id: 1)),
    );

    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.singleton((_) => SyncOtherServiceMock(id: 2)),
    );

    final instance = SyncBind.get<SyncOtherServiceMock>();
    expect(instance.id, equals(2));
  });

  test('clearAll should dispose all and clear binds', () {
    SyncBind.register<SyncOtherServiceMock>(
      SyncBind.singleton((_) => SyncOtherServiceMock(id: 1)),
    );
    SyncBind.register<SyncServiceMock>(
      SyncBind.singleton((_) => SyncServiceMock()),
    );

    expect(SyncBind.get<SyncOtherServiceMock>(), isNotNull);
    expect(SyncBind.get<SyncServiceMock>(), isNotNull);

    SyncBind.clearAll();

    expect(() => SyncBind.get<SyncOtherServiceMock>(), throwsException);
    expect(() => SyncBind.get<SyncServiceMock>(), throwsException);
  });

  test('disposeInstance should close StreamController', () {
    final controller = StreamController();

    SyncBind.register<StreamController>(SyncBind.singleton((_) => controller));

    SyncBind.get<StreamController>();

    SyncBind.disposeByType(StreamController);

    expect(controller.isClosed, isTrue);
  });
}
