import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';

import 'package:modugo/src/models/binding_key_model.dart';

void main() {
  setUp(() => Injector().clearAll());

  group('BindingKey Tests', () {
    test('should create BindingKey with key and type', () {
      const key = BindingKeyModel<String>('test');

      expect(key.key, equals('test'));
      expect(key.type, equals(String));
    });

    test('should create default key', () {
      const key = BindingKeyModel<String>.defaultKey();

      expect(key.key, equals(''));
      expect(key.type, equals(String));
    });

    test('should handle equality correctly', () {
      const key1 = BindingKeyModel<String>('test');
      const key2 = BindingKeyModel<String>('test');
      const key3 = BindingKeyModel<String>('different');
      const key4 = BindingKeyModel<int>('test');

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
      expect(key1, isNot(equals(key4)));
    });

    test('should handle hashCode correctly', () {
      const key1 = BindingKeyModel<String>('test');
      const key2 = BindingKeyModel<String>('test');

      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('should create typed key from Type', () {
      final key = BindingKeyModel.fromType(String, 'test');

      expect(key.key, equals('test'));
      expect(key.type, equals(String));
    });
  });

  group('Key-based Dependency Injection with String Keys', () {
    test(
      'should register multiple instances of same type with different string keys',
      () {
        Injector()
          ..addSingleton<String>((i) => 'Primary Database', key: 'primary')
          ..addSingleton<String>((i) => 'Secondary Database', key: 'secondary');

        final primary = Injector().get<String>(key: 'primary');
        final secondary = Injector().get<String>(key: 'secondary');

        expect(primary, equals('Primary Database'));
        expect(secondary, equals('Secondary Database'));
      },
    );

    test('should support factory binding with string keys', () {
      int callCount = 0;

      Injector().addFactory<_CounterMock>(
        (i) => _CounterMock(++callCount),
        key: 'factory',
      );

      final first = Injector().get<_CounterMock>(key: 'factory');
      final second = Injector().get<_CounterMock>(key: 'factory');

      expect(first.value, equals(1));
      expect(second.value, equals(2));
      expect(identical(first, second), isFalse);
    });

    test('should support lazy singleton binding with string keys', () {
      int callCount = 0;

      Injector().addLazySingleton<_CounterMock>(
        key: 'lazy',
        (i) => _CounterMock(++callCount),
      );

      final first = Injector().get<_CounterMock>(key: 'lazy');
      final second = Injector().get<_CounterMock>(key: 'lazy');

      expect(first.value, equals(1));
      expect(second.value, equals(1));
      expect(identical(first, second), isTrue);
    });

    test('should work with default keys (backward compatibility)', () {
      Injector().addSingleton<String>((i) => 'Default Value');

      final value = Injector().get<String>();

      expect(value, equals('Default Value'));
    });

    test('should mix keyed and non-keyed registrations', () {
      Injector()
        ..addSingleton<String>((i) => 'Default') // Default key
        ..addSingleton<String>((i) => 'Keyed', key: 'keyed');

      final defaultValue = Injector().get<String>();
      final keyedValue = Injector().get<String>(key: 'keyed');

      expect(defaultValue, equals('Default'));
      expect(keyedValue, equals('Keyed'));
    });

    test('should check registration correctly with string keys', () {
      expect(Injector().isRegistered<String>(), isFalse);
      expect(Injector().isRegistered<String>(key: 'test'), isFalse);

      Injector().addSingleton<String>((i) => 'Test', key: 'test');

      expect(Injector().isRegistered<String>(), isFalse);
      expect(Injector().isRegistered<String>(key: 'test'), isTrue);
    });

    test('should dispose by string key correctly', () {
      Injector()
        ..addSingleton<_DisposableMock>(
          (i) => _DisposableMock(),
          key: 'service1',
        )
        ..addSingleton<_DisposableMock>(
          (i) => _DisposableMock(),
          key: 'service2',
        );

      final service1 = Injector().get<_DisposableMock>(key: 'service1');
      final service2 = Injector().get<_DisposableMock>(key: 'service2');

      Injector().dispose<_DisposableMock>(key: 'service1');

      expect(service1.disposed, isTrue);
      expect(service2.disposed, isFalse);
      expect(
        Injector().isRegistered<_DisposableMock>(key: 'service1'),
        isFalse,
      );
      expect(Injector().isRegistered<_DisposableMock>(key: 'service2'), isTrue);
    });

    test(
      'should dispose by type correctly (disposes all keys of that type)',
      () {
        Injector()
          ..addSingleton<_DisposableMock>(
            (i) => _DisposableMock(),
            key: 'service1',
          )
          ..addSingleton<_DisposableMock>(
            (i) => _DisposableMock(),
            key: 'service2',
          );

        final service1 = Injector().get<_DisposableMock>(key: 'service1');
        final service2 = Injector().get<_DisposableMock>(key: 'service2');

        Injector().disposeByType(_DisposableMock);

        expect(service1.disposed, isTrue);
        expect(service2.disposed, isTrue);
        expect(
          Injector().isRegistered<_DisposableMock>(key: 'service1'),
          isFalse,
        );
        expect(
          Injector().isRegistered<_DisposableMock>(key: 'service2'),
          isFalse,
        );
      },
    );

    test('should dispose by specific binding key', () {
      Injector().addSingleton<_DisposableMock>(
        (i) => _DisposableMock(),
        key: 'service',
      );

      final service = Injector().get<_DisposableMock>(key: 'service');
      final bindingKey = BindingKeyModel<_DisposableMock>('service');

      Injector().disposeByKey(bindingKey);

      expect(service.disposed, isTrue);
      expect(Injector().isRegistered<_DisposableMock>(key: 'service'), isFalse);
    });

    test('should return registered keys', () {
      Injector()
        ..addSingleton<String>((i) => 'Value1', key: 'key1')
        ..addSingleton<int>((i) => 42, key: 'key2');

      final registeredKeys = Injector().registeredKeys;

      expect(
        registeredKeys.any((k) => k.key == 'key1' && k.type == String),
        isTrue,
      );
      expect(
        registeredKeys.any((k) => k.key == 'key2' && k.type == int),
        isTrue,
      );
      expect(registeredKeys.length, equals(2));
    });

    test('should return registered types', () {
      Injector()
        ..addSingleton<String>((i) => 'Value', key: 'string')
        ..addSingleton<int>((i) => 42, key: 'int');

      final registeredTypes = Injector().registeredTypes;

      expect(registeredTypes, contains(String));
      expect(registeredTypes, contains(int));
      expect(registeredTypes.length, equals(2));
    });

    test('should throw when trying to get unregistered key', () {
      expect(
        () => Injector().get<String>(key: 'nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle empty string key as default key', () {
      Injector().addSingleton<String>((i) => 'Also Default');

      final value = Injector().get<String>();

      expect(value, equals('Also Default'));
    });

    test('should handle null key as default key', () {
      Injector().addSingleton<String>((i) => 'Default Value', key: null);

      final value = Injector().get<String>();

      expect(value, equals('Default Value'));
    });
  });
}

final class _CounterMock {
  final int value;
  _CounterMock(this.value);
}

final class _DisposableMock {
  bool disposed = false;

  void dispose() {
    disposed = true;
  }
}
