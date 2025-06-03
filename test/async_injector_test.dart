import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injectors/injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';

import 'mocks/services_mock.dart';

void main() {
  setUpAll(() async {
    await AsyncBind.clearAll();
    AsyncBind.clearAll();
  });

  test('Async singleton resolves only once', () async {
    int callCount = 0;

    AsyncBind.register<String>(
      AsyncBind((_) async {
        callCount++;
        return 'Hello';
      }),
    );

    final result1 = await Injector().getAsync<String>();
    final result2 = await Injector().getAsync<String>();

    expect(result1, equals('Hello'));
    expect(result2, equals('Hello'));
    expect(callCount, equals(1));
  });

  test('Async factory resolves each time', () async {
    int callCount = 0;

    AsyncBind.register<String>(
      AsyncBind((_) async {
        callCount++;
        return 'Call $callCount';
      }, isSingleton: false),
    );

    final result1 = await Injector().getAsync<String>();
    final result2 = await Injector().getAsync<String>();

    expect(result1, isNot(equals(result2)));
    expect(callCount, equals(2));
  });

  test('Dispose async singleton clears instance', () async {
    bool closed = false;

    AsyncBind.register<AsyncServiceMock>(
      AsyncBind(
        (_) async => AsyncServiceMock(onClose: () => closed = true),
        disposeAsync: (instance) async => instance.close(),
      ),
    );

    final instance = await Injector().getAsync<AsyncServiceMock>();
    expect(instance, isNotNull);

    await AsyncBind.disposeByType(AsyncServiceMock);

    expect(closed, isTrue);
    expect(() => Injector().getAsync<AsyncServiceMock>(), throwsException);
  });

  test('ClearAll clears all async binds', () async {
    bool closedA = false;
    bool closedB = false;

    AsyncBind.register<AsyncServiceMock>(
      AsyncBind(
        (_) async => AsyncServiceMock(onClose: () => closedA = true),
        disposeAsync: (instance) async => instance.close(),
      ),
    );

    AsyncBind.register<AsyncOtherServiceMock>(
      AsyncBind(
        (_) async => AsyncOtherServiceMock(onClose: () => closedB = true),
        disposeAsync: (instance) async => instance.close(),
      ),
    );

    await Injector().getAsync<AsyncServiceMock>();
    await Injector().getAsync<AsyncOtherServiceMock>();

    await AsyncBind.clearAll();

    expect(closedA, isTrue);
    expect(closedB, isTrue);

    expect(() => Injector().getAsync<AsyncServiceMock>(), throwsException);
    expect(() => Injector().getAsync<AsyncOtherServiceMock>(), throwsException);
  });

  test('Concurrent async singleton calls await same future', () async {
    int callCount = 0;

    AsyncBind.register<String>(
      AsyncBind((_) async {
        callCount++;
        await Future.delayed(Duration(milliseconds: 100));
        return 'Concurrent';
      }),
    );

    final futures = [
      Injector().getAsync<String>(),
      Injector().getAsync<String>(),
      Injector().getAsync<String>(),
    ];

    final results = await Future.wait(futures);

    expect(results[0], equals('Concurrent'));
    expect(results[1], equals('Concurrent'));
    expect(results[2], equals('Concurrent'));
    expect(callCount, equals(1));
  });

  test('Async factory respects manual timeout simulation', () async {
    AsyncBind.register<String>(
      AsyncBind((_) async {
        await Future.delayed(Duration(seconds: 1));
        return 'Late';
      }),
    );

    final future = Injector().getAsync<String>().timeout(
      Duration(milliseconds: 100),
      onTimeout: () => 'TimeoutFallback',
    );

    final result = await future;
    expect(result, equals('TimeoutFallback'));
  });

  test('Re-registering async bind overrides previous', () async {
    AsyncBind.register<String>(AsyncBind((_) async => 'First'));

    final first = await Injector().getAsync<String>();
    expect(first, equals('First'));

    AsyncBind.register<String>(AsyncBind((_) async => 'Second'));

    final second = await Injector().getAsync<String>();
    expect(second, equals('Second'));
  });

  test('Multiple async types coexist and resolve correctly', () async {
    AsyncBind.register<String>(AsyncBind((_) async => 'StringValue'));

    AsyncBind.register<int>(AsyncBind((_) async => 42));

    final stringValue = await Injector().getAsync<String>();
    final intValue = await Injector().getAsync<int>();

    expect(stringValue, equals('StringValue'));
    expect(intValue, equals(42));
  });

  test('Async factory throws error and does not cache result', () async {
    int callCount = 0;

    AsyncBind.register<String>(
      AsyncBind((_) async {
        callCount++;
        throw Exception('Factory error');
      }),
    );

    expect(() => Injector().getAsync<String>(), throwsException);

    expect(() => Injector().getAsync<String>(), throwsException);

    expect(callCount, equals(1));
  });
}
