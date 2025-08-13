import 'package:flutter/material.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/event.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/routes/child_route.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    modularNavigatorKey = GlobalKey<NavigatorState>();
  });

  group('ModugoEventModule Singleton', () {
    test('should be a singleton', () {
      final instance1 = ModugoEventModule.instance;
      final instance2 = ModugoEventModule.instance;

      expect(instance1, equals(instance2));
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('ModugoEventModule Static Methods', () {
    test('should fire events with static fire method', () {
      expect(
        () => ModugoEventModule.fire(const _EventMock('Static fire test')),
        returnsNormally,
      );
    });
  });

  group('EventModule', () {
    late _EventModule eventModule;

    setUp(() {
      eventModule = _EventModule();
    });

    tearDown(() {
      try {
        eventModule.dispose();
      } catch (_) {}
    });

    group('Initialization', () {
      test('should call listen() during initState', () async {
        expect(eventModule.receivedValues.isEmpty, isTrue);
        expect(eventModule.receivedMessages.isEmpty, isTrue);

        eventModule.initState();

        ModugoEventModule.fire(const _EventMock('Init test'));
        ModugoEventModule.fire(const _AnotherEventMock(123));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventModule.receivedValues.length, equals(1));
        expect(eventModule.receivedValues.first, equals(123));
        expect(eventModule.receivedMessages.length, equals(1));
        expect(eventModule.receivedMessages.first, equals('Init test'));
      });

      test('should work with custom EventBus', () async {
        final customEventBus = EventBus();
        final customEventModule = _EventModule(eventBus: customEventBus);

        customEventModule.initState();

        ModugoEventModule.fire(const _EventMock('Default bus'));
        await Future.delayed(const Duration(milliseconds: 100));
        expect(customEventModule.receivedMessages.length, equals(0));

        ModugoEventModule.fire(
          const _EventMock('Custom bus'),
          eventBus: customEventBus,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        expect(customEventModule.receivedMessages.length, equals(1));
        expect(customEventModule.receivedMessages.first, equals('Custom bus'));

        customEventModule.dispose();
      });
    });

    group('Event Listening', () {
      test('should receive events through on() method', () async {
        eventModule.initState();

        const event3 = _AnotherEventMock(100);
        const event1 = _EventMock('Message 1');
        const event2 = _EventMock('Message 2');

        ModugoEventModule.fire(event1);
        ModugoEventModule.fire(event2);
        ModugoEventModule.fire(event3);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventModule.receivedValues.length, equals(1));
        expect(eventModule.receivedValues.first, equals(100));
        expect(eventModule.receivedMessages.length, equals(2));
        expect(eventModule.receivedMessages, contains('Message 1'));
        expect(eventModule.receivedMessages, contains('Message 2'));
      });

      test('should handle multiple events of same type', () async {
        eventModule.initState();

        for (int i = 0; i < 5; i++) {
          ModugoEventModule.fire(_EventMock('Message $i'));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventModule.receivedMessages.length, equals(5));
        for (int i = 0; i < 5; i++) {
          expect(eventModule.receivedMessages, contains('Message $i'));
        }
      });
    });

    group('Auto Dispose', () {
      test('should dispose correctly when module is disposed', () async {
        eventModule.initState();

        ModugoEventModule.fire(const _EventMock('Before dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(() => eventModule.dispose(), returnsNormally);
        expect(eventModule.receivedMessages.length, equals(1));
        expect(eventModule.receivedMessages.first, equals('Before dispose'));
      });

      test('should not dispose listeners when autoDispose is false', () async {
        final noAutoDisposeModule = _EventModuleNoAutoDispose();

        noAutoDisposeModule.initState();

        ModugoEventModule.fire(const _EventMock('Before dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(noAutoDisposeModule.receivedMessages.length, equals(1));

        noAutoDisposeModule.dispose();

        ModugoEventModule.fire(const _EventMock('After dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(noAutoDisposeModule.receivedMessages.length, equals(2));
        expect(
          noAutoDisposeModule.receivedMessages,
          contains('Before dispose'),
        );
        expect(noAutoDisposeModule.receivedMessages, contains('After dispose'));

        try {
          ModugoEventModule.instance.dispose<_EventMock>();
        } catch (_) {}
      });
    });

    group('Routes', () {
      test('should have routes defined', () {
        final routes = eventModule.routes();

        expect(routes, isNotEmpty);
        expect(routes.length, equals(1));
        expect(routes.first, isA<ChildRoute>());
      });
    });
  });

  group('Integration Tests', () {
    test('should work with multiple EventModules', () async {
      final module1 = _EventModule();
      final module2 = _EventModule();

      module1.initState();
      module2.initState();

      const testEvent = _EventMock('Shared event');
      ModugoEventModule.fire(testEvent);

      await Future.delayed(const Duration(milliseconds: 200));

      final total1 = module1.receivedMessages.length;
      final total2 = module2.receivedMessages.length;

      expect(total1 + total2, greaterThan(0));

      if (total1 > 0) {
        expect(module1.receivedMessages, contains('Shared event'));
      }

      if (total2 > 0) {
        expect(module2.receivedMessages, contains('Shared event'));
      }

      module1.dispose();
      module2.dispose();
    });

    test('should create and dispose EventModule without errors', () async {
      final eventModule = _EventModule();

      expect(() => eventModule.initState(), returnsNormally);

      expect(
        () => ModugoEventModule.fire(const _EventMock('Test message')),
        returnsNormally,
      );

      expect(() => eventModule.dispose(), returnsNormally);
    });
  });

  group('EventBus Integration', () {
    test('should work with custom EventBus instances', () async {
      final customEventBus1 = EventBus();
      final customEventBus2 = EventBus();

      final module1 = _EventModule(eventBus: customEventBus1);
      final module2 = _EventModule(eventBus: customEventBus2);

      module1.initState();
      module2.initState();

      ModugoEventModule.fire(
        const _EventMock('Bus 1 event'),
        eventBus: customEventBus1,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(module1.receivedMessages.length, equals(1));
      expect(module2.receivedMessages.length, equals(0));

      ModugoEventModule.fire(
        const _EventMock('Bus 2 event'),
        eventBus: customEventBus2,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(module1.receivedMessages.length, equals(1));
      expect(module2.receivedMessages.length, equals(1));

      expect(module1.receivedMessages.first, equals('Bus 1 event'));
      expect(module2.receivedMessages.first, equals('Bus 2 event'));

      module1.dispose();
      module2.dispose();
    });

    test('should handle EventBus lifecycle correctly', () {
      final customEventBus = EventBus();
      final eventModule = _EventModule(eventBus: customEventBus);

      expect(() => eventModule.initState(), returnsNormally);
      expect(
        () => ModugoEventModule.fire(
          const _EventMock('Test'),
          eventBus: customEventBus,
        ),
        returnsNormally,
      );
      expect(() => eventModule.dispose(), returnsNormally);
    });
  });
}

final class _EventMock {
  final String message;
  const _EventMock(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EventMock &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TestEvent{message: $message}';
}

final class _AnotherEventMock {
  final int value;
  const _AnotherEventMock(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AnotherEventMock &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AnotherTestEvent{value: $value}';
}

final class _EventModule extends EventModule {
  final List<int> receivedValues = [];
  final List<String> receivedMessages = [];

  _EventModule({super.eventBus});

  @override
  List<IModule> routes() => [
    ChildRoute(path: '/', child: (context, state) => const Scaffold()),
  ];

  @override
  void listen() {
    on<_EventMock>((event, context) {
      receivedMessages.add(event.message);
    });

    on<_AnotherEventMock>((event, context) {
      receivedValues.add(event.value);
    });
  }
}

final class _EventModuleNoAutoDispose extends EventModule {
  final List<String> receivedMessages = [];

  // ignore: unused_element_parameter
  _EventModuleNoAutoDispose({super.eventBus});

  @override
  List<IModule> routes() => [
    ChildRoute(path: '/', child: (context, state) => const Scaffold()),
  ];

  @override
  void listen() {
    on<_EventMock>((event, context) {
      receivedMessages.add(event.message);
    }, autoDispose: false);
  }
}
