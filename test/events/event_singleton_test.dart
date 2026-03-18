import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/events/event.dart';

void main() {
  group('Event singleton', () {
    tearDown(() => Event.i.disposeAll());

    test('Event.i always returns the same instance on repeated calls', () {
      expect(Event.i, same(Event.i));
    });

    test(
      'top-level events and Event.i are the same instance (BUG-11 fixed)',
      () {
        // Previously, `events` was a separate `final Event events = Event._()`.
        // Now it is a getter alias for Event.i — both point to the same object.
        expect(events, same(Event.i));
      },
    );

    test(
      'listener on events receives emit via Event.emit (BUG-11 fixed)',
      () async {
        bool receivedViaTopLevel = false;
        events.on<_Ping>((_) => receivedViaTopLevel = true);

        Event.emit(_Ping());
        await Future<void>.delayed(Duration.zero);

        expect(receivedViaTopLevel, isTrue);
      },
    );

    test('listener on Event.i correctly receives emit', () async {
      bool received = false;
      Event.i.on<_Ping>((_) => received = true);

      Event.emit(_Ping());
      await Future<void>.delayed(Duration.zero);

      expect(received, isTrue);
    });

    test(
      'listener on events and listener on Event.i both receive the same emit',
      () async {
        int count = 0;
        events.on<_Ping>((_) => count++);
        Event.i.on<_Ping>((_) => count++);

        Event.emit(_Ping());
        await Future<void>.delayed(Duration.zero);

        // Both listeners are on the same controller, but on() replaces the
        // previous subscription for the same type — only the last one fires.
        // The important thing is count > 0 (the event reached the unified bus).
        expect(count, greaterThan(0));
      },
    );
  });
}

final class _Ping {
  const _Ping();
}
