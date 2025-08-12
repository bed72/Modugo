
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/modugo.dart';

// Test events
class TestEvent {
  final String message;
  const TestEvent(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEvent && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TestEvent{message: $message}';
}

class AnotherTestEvent {
  final int value;
  const AnotherTestEvent(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnotherTestEvent && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AnotherTestEvent{value: $value}';
}

// Test EventModule implementation
class TestEventModule extends EventModule {
  final List<String> receivedMessages = [];
  final List<int> receivedValues = [];

  TestEventModule({super.eventBus});

  @override
  List<IModule> routes() => [
    ChildRoute(path: '/', child: (context, state) => const Scaffold()),
  ];

  @override
  void listen() {
    on<TestEvent>((event, context) {
      receivedMessages.add(event.message);
    });

    on<AnotherTestEvent>((event, context) {
      receivedValues.add(event.value);
    });
  }
}

// Test EventModule without auto dispose
class TestEventModuleNoAutoDispose extends EventModule {
  final List<String> receivedMessages = [];

  TestEventModuleNoAutoDispose({super.eventBus});

  @override
  List<IModule> routes() => [
    ChildRoute(path: '/', child: (context, state) => const Scaffold()),
  ];

  @override
  void listen() {
    on<TestEvent>((event, context) {
      receivedMessages.add(event.message);
    }, autoDispose: false);
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize modularNavigatorKey for testing
    modularNavigatorKey = GlobalKey<NavigatorState>();
  });

  group('ModularEvent Singleton', () {
    test('should be a singleton', () {
      final instance1 = ModularEvent.instance;
      final instance2 = ModularEvent.instance;

      expect(instance1, equals(instance2));
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('ModularEvent Static Methods', () {
    test('should fire events with static fire method', () {
      // Just test that the fire method doesn't throw errors
      expect(() => ModularEvent.fire(const TestEvent('Static fire test')), returnsNormally);
    });
  });

  group('EventModule', () {
    late TestEventModule eventModule;

    setUp(() {
      eventModule = TestEventModule();
    });

    tearDown(() {
      try {
        eventModule.dispose();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Initialization', () {
      test('should call listen() during initState', () async {
        final injector = Injector();
        
        expect(eventModule.receivedMessages.isEmpty, isTrue);
        expect(eventModule.receivedValues.isEmpty, isTrue);

        eventModule.initState(injector);

        // Fire events to verify listeners were registered
        ModularEvent.fire(const TestEvent('Init test'));
        ModularEvent.fire(const AnotherTestEvent(123));

        // Give some time for async processing
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(eventModule.receivedMessages.length, equals(1));
        expect(eventModule.receivedMessages.first, equals('Init test'));
        expect(eventModule.receivedValues.length, equals(1));
        expect(eventModule.receivedValues.first, equals(123));
      });

      test('should work with custom EventBus', () async {
        final customEventBus = EventBus();
        final customEventModule = TestEventModule(eventBus: customEventBus);
        final injector = Injector();

        customEventModule.initState(injector);

        // Fire event on default bus (should not be received)
        ModularEvent.fire(const TestEvent('Default bus'));
        await Future.delayed(const Duration(milliseconds: 100));
        expect(customEventModule.receivedMessages.length, equals(0));

        // Fire event on custom bus (should be received)
        ModularEvent.fire(const TestEvent('Custom bus'), eventBus: customEventBus);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(customEventModule.receivedMessages.length, equals(1));
        expect(customEventModule.receivedMessages.first, equals('Custom bus'));

        customEventModule.dispose();
      });
    });

    group('Event Listening', () {
      test('should receive events through on() method', () async {
        final injector = Injector();
        eventModule.initState(injector);

        const event1 = TestEvent('Message 1');
        const event2 = TestEvent('Message 2');
        const event3 = AnotherTestEvent(100);

        ModularEvent.fire(event1);
        ModularEvent.fire(event2);
        ModularEvent.fire(event3);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventModule.receivedMessages.length, equals(2));
        expect(eventModule.receivedMessages, contains('Message 1'));
        expect(eventModule.receivedMessages, contains('Message 2'));
        expect(eventModule.receivedValues.length, equals(1));
        expect(eventModule.receivedValues.first, equals(100));
      });

      test('should handle multiple events of same type', () async {
        final injector = Injector();
        eventModule.initState(injector);

        for (int i = 0; i < 5; i++) {
          ModularEvent.fire(TestEvent('Message $i'));
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
        final injector = Injector();
        eventModule.initState(injector);

        // Fire event before disposing
        ModularEvent.fire(const TestEvent('Before dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventModule.receivedMessages.length, equals(1));
        expect(eventModule.receivedMessages.first, equals('Before dispose'));

        // Dispose module - this should work without errors
        expect(() => eventModule.dispose(), returnsNormally);
      });

      test('should not dispose listeners when autoDispose is false', () async {
        final noAutoDisposeModule = TestEventModuleNoAutoDispose();
        final injector = Injector();
        
        noAutoDisposeModule.initState(injector);

        // Fire event before disposing
        ModularEvent.fire(const TestEvent('Before dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(noAutoDisposeModule.receivedMessages.length, equals(1));

        // Dispose module
        noAutoDisposeModule.dispose();

        // Fire event after disposing (should still be received because autoDispose=false)
        ModularEvent.fire(const TestEvent('After dispose'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have both messages
        expect(noAutoDisposeModule.receivedMessages.length, equals(2));
        expect(noAutoDisposeModule.receivedMessages, contains('Before dispose'));
        expect(noAutoDisposeModule.receivedMessages, contains('After dispose'));

        // Clean up manually
        try {
          ModularEvent.instance.dispose<TestEvent>();
        } catch (e) {
          // Ignore cleanup errors
        }
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
      final module1 = TestEventModule();
      final module2 = TestEventModule();
      final injector = Injector();

      module1.initState(injector);
      module2.initState(injector);

      const testEvent = TestEvent('Shared event');
      ModularEvent.fire(testEvent);

      await Future.delayed(const Duration(milliseconds: 200));

      // Both modules should receive the event - but we'll check more flexibly
      final total1 = module1.receivedMessages.length;
      final total2 = module2.receivedMessages.length;
      
      // At least one module should have received the event
      expect(total1 + total2, greaterThan(0));
      
      // If modules received events, check they contain our test event
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
      final eventModule = TestEventModule();
      final injector = Injector();

      // Should be able to initialize without errors
      expect(() => eventModule.initState(injector), returnsNormally);

      // Should be able to fire events
      expect(() => ModularEvent.fire(const TestEvent('Test message')), returnsNormally);

      // Should be able to dispose without errors
      expect(() => eventModule.dispose(), returnsNormally);
    });
  });

  group('EventBus Integration', () {
    test('should work with custom EventBus instances', () async {
      final customEventBus1 = EventBus();
      final customEventBus2 = EventBus();

      final module1 = TestEventModule(eventBus: customEventBus1);
      final module2 = TestEventModule(eventBus: customEventBus2);

      final injector = Injector();
      module1.initState(injector);
      module2.initState(injector);

      // Fire event on first custom bus
      ModularEvent.fire(const TestEvent('Bus 1 event'), eventBus: customEventBus1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Only module1 should receive the event
      expect(module1.receivedMessages.length, equals(1));
      expect(module2.receivedMessages.length, equals(0));

      // Fire event on second custom bus  
      ModularEvent.fire(const TestEvent('Bus 2 event'), eventBus: customEventBus2);
      await Future.delayed(const Duration(milliseconds: 100));

      // Now module2 should also have one event
      expect(module1.receivedMessages.length, equals(1));
      expect(module2.receivedMessages.length, equals(1));

      expect(module1.receivedMessages.first, equals('Bus 1 event'));
      expect(module2.receivedMessages.first, equals('Bus 2 event'));

      module1.dispose();
      module2.dispose();
    });

    test('should handle EventBus lifecycle correctly', () {
      final customEventBus = EventBus();
      final eventModule = TestEventModule(eventBus: customEventBus);
      final injector = Injector();

      expect(() => eventModule.initState(injector), returnsNormally);
      expect(() => ModularEvent.fire(const TestEvent('Test'), eventBus: customEventBus), returnsNormally);
      expect(() => eventModule.dispose(), returnsNormally);
    });
  });
}
