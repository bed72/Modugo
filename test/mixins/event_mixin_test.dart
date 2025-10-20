import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';

import 'package:modugo/src/mixins/event_mixin.dart';

void main() {
  group('IEvent Tests', () {
    late _EventModule module;

    setUp(() {
      module = _EventModule();
    });

    test('initState calls listen', () async {
      final completer = Completer<void>();

      final module2 = _EventModule(onEventCalled: (_) => completer.complete());

      module2.initState();

      await Future<void>.delayed(Duration.zero);

      Event.emit(_EventMock('Hello'));

      await completer.future;
      expect(completer.isCompleted, true);

      module2.dispose();
    });

    test('on<T>() registers listener and fires callback', () async {
      final completer = Completer<void>();
      final module = _EventModule(
        onEventCalled: (event) {
          expect(event.message, 'Test');
          completer.complete();
        },
      );

      module.initState();

      Event.emit(_EventMock('Test'));

      await completer.future;
      expect(completer.isCompleted, true);

      module.dispose();
    });

    test('dispose cancels subscriptions', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true, autoDispose: true);

      module.dispose();

      Event.emit(_EventMock('Test'));

      await Future.delayed(Duration.zero);

      expect(callbackCalled, false);
    });

    test('disposeAll disposes all Event listeners', () async {
      bool callbackCalled = false;

      module.on<_EventMock>((_) => callbackCalled = true);

      module.dispose();

      Event.emit(_EventMock('Test'));

      await Future.delayed(Duration.zero);
      expect(callbackCalled, false);
    });
  });
}

final class _EventMock {
  final String message;
  _EventMock(this.message);
}

final class _EventModule extends Module with IEvent {
  final void Function(_EventMock event)? onEventCalled;

  _EventModule({this.onEventCalled});

  @override
  void listen() {
    on<_EventMock>((event) {
      if (onEventCalled != null) onEventCalled!(event);
    }, autoDispose: true);
  }
}
