import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/events/event_channel.dart';
import 'package:modugo/src/registers/event_registry.dart';

void main() {
  group('EventRegistry Tests', () {
    late _EventModule module;

    setUp(() {
      module = _EventModule();
    });

    test('initState calls listen', () async {
      final completer = Completer<void>();

      final module2 = _EventModule(onEventCalled: (_) => completer.complete());

      module2.initState();

      EventChannel.emit(_EventMock('Hello'));

      await completer.future;

      expect(completer.isCompleted, true);
    });

    test('on<T>() registers listener and fires callback', () async {
      final completer = Completer<void>();

      module.on<_EventMock>((event) {
        expect(event.message, 'Test');
        completer.complete();
      });

      EventChannel.emit(_EventMock('Test'));

      await completer.future;

      expect(completer.isCompleted, true);
    });

    test('dispose cancels subscriptions', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true, autoDispose: true);

      module.dispose();

      EventChannel.emit(_EventMock('Test'));

      await Future.delayed(Duration.zero);

      expect(callbackCalled, false);
    });

    test('disposeAll disposes all EventChannel listeners', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true);

      module.dispose();

      EventChannel.emit(_EventMock('Test'));

      await Future.delayed(Duration.zero);
      expect(callbackCalled, false);
    });
  });
}

final class _EventMock {
  final String message;
  _EventMock(this.message);
}

final class _EventModule extends Module with EventRegistry {
  final void Function(_EventMock event)? onEventCalled;

  _EventModule({this.onEventCalled});

  @override
  void listen() {
    on<_EventMock>((event) {
      if (onEventCalled != null) onEventCalled!(event);
    }, autoDispose: true);
  }
}
