import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/events/event_module.dart';
import 'package:modugo/src/events/event_channel.dart';

void main() {
  group('EventModule Tests', () {
    late EventBus eventBus;
    late _EventModule module;

    setUp(() {
      eventBus = EventBus();
      module = _EventModule(eventBus: eventBus);
    });

    test('initState calls listen', () async {
      final completer = Completer<void>();

      final module2 = _EventModule(
        eventBus: eventBus,
        onEventCalled: (_) => completer.complete(),
      );

      module2.initState();

      EventChannel.emit(_EventMock('Hello'), eventBus: eventBus);

      await completer.future;

      expect(completer.isCompleted, true);
    });

    test('on<T>() registers listener and fires callback', () async {
      final completer = Completer<void>();

      module.on<_EventMock>((event) {
        expect(event.message, 'Test');
        completer.complete();
      });

      EventChannel.emit(_EventMock('Test'), eventBus: eventBus);

      await completer.future;

      expect(completer.isCompleted, true);
    });

    test('dispose cancels subscriptions', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true, autoDispose: true);

      module.dispose();

      EventChannel.emit(_EventMock('Test'), eventBus: eventBus);

      await Future.delayed(Duration.zero);

      expect(callbackCalled, false);
    });

    test('disposeAll disposes all EventChannel listeners', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true);

      module.dispose();

      EventChannel.emit(_EventMock('Test'), eventBus: eventBus);

      await Future.delayed(Duration.zero);
      expect(callbackCalled, false);
    });
  });
}

final class _EventMock {
  final String message;
  _EventMock(this.message);
}

final class _EventModule extends EventModule {
  final void Function(_EventMock event)? onEventCalled;

  _EventModule({super.eventBus, this.onEventCalled});

  @override
  void listen() {
    on<_EventMock>((event) {
      if (onEventCalled != null) onEventCalled!(event);
    }, autoDispose: true);
  }
}
