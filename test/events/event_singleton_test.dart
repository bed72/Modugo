import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/events/event.dart';

/// Documents BUG-11: the top-level `events` variable and `Event.i` are
/// different instances. Emitting via one does NOT reach listeners on the other.
///
/// These tests document the *current* (broken) behavior so that a fix can be
/// tracked and verified. When BUG-11 is resolved, the "diverge" test should
/// be updated to show that both paths reach the same listeners.
void main() {
  group('Event singleton — BUG-11 documentation', () {
    tearDown(() {
      Event.i.disposeAll();
      // The top-level `events` is a separate instance — it has its own state.
    });

    test('Event.i always returns the same instance on repeated calls', () {
      expect(Event.i, same(Event.i));
    });

    test('[BUG-11] top-level events and Event.i are different instances', () {
      // This test documents the existing bug: the top-level `events` global
      // and Event.i are created separately and hold different _controllers maps.
      expect(events, isNot(same(Event.i)));
    });

    test(
      '[BUG-11] listener registered on events does not receive emit via Event.i',
      () async {
        // Registering on the top-level `events` instance.
        bool receivedViaTopLevel = false;
        events.on<_Ping>((_) => receivedViaTopLevel = true);

        // Emitting via the static Event.emit (which uses Event.i internally).
        Event.emit(_Ping());
        await Future<void>.delayed(Duration.zero);

        // Because events != Event.i, the listener is never reached.
        expect(receivedViaTopLevel, isFalse);
      },
    );

    test(
      '[BUG-11] listener registered on Event.i correctly receives emit',
      () async {
        bool received = false;
        Event.i.on<_Ping>((_) => received = true);

        Event.emit(_Ping());
        await Future<void>.delayed(Duration.zero);

        expect(received, isTrue);
      },
    );
  });
}

final class _Ping {
  const _Ping();
}
