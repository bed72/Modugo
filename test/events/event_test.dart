import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/events/event.dart';

void main() {
  group('Event', () {
    setUp(() {
      Event.i.disposeAll();
    });

    test('should return same singleton instance', () {
      final first = Event.i;
      final second = Event.i;
      expect(first, same(second));
    });

    test('should broadcast same event to all listeners of same type', () async {
      bool firstCalled = false;
      bool secondCalled = false;

      Event.i.streamOf<_LoginEvent>().listen((_) => firstCalled = true);
      Event.i.streamOf<_LoginEvent>().listen((_) => secondCalled = true);

      Event.emit(_LoginEvent('gabriel'));
      await Future<void>.delayed(Duration.zero);

      expect(firstCalled, isTrue);
      expect(secondCalled, isTrue);
    });

    test('should emit and receive typed event through on()', () async {
      final completer = Completer<_LoginEvent>();
      Event.i.on<_LoginEvent>((event) => completer.complete(event));

      Event.emit(_LoginEvent('gabriel'));
      final received = await completer.future;

      expect(received.user, equals('gabriel'));
    });

    test('should not throw when emitting without listeners', () {
      expect(() => Event.emit(_LogoutEvent('none')), returnsNormally);
    });

    test('should dispose specific subscription', () async {
      int count = 0;
      Event.i.on<_LoginEvent>((_) => count++);

      Event.emit(_LoginEvent('1'));
      await Future<void>.delayed(Duration.zero);
      expect(count, equals(1));

      Event.i.dispose<_LoginEvent>();
      Event.emit(_LoginEvent('2'));
      await Future<void>.delayed(Duration.zero);

      expect(count, equals(1));
    });

    test('should dispose all subscriptions and controllers', () async {
      bool loginCalled = false;
      bool logoutCalled = false;

      Event.i.on<_LoginEvent>((_) => loginCalled = true);
      Event.i.on<_LogoutEvent>((_) => logoutCalled = true);

      Event.emit(_LoginEvent('1'));
      Event.emit(_LogoutEvent('1'));
      await Future<void>.delayed(Duration.zero);

      expect(loginCalled, isTrue);
      expect(logoutCalled, isTrue);

      Event.i.disposeAll();

      loginCalled = false;
      logoutCalled = false;
      Event.emit(_LoginEvent('2'));
      Event.emit(_LogoutEvent('2'));
      await Future<void>.delayed(Duration.zero);

      expect(loginCalled, isFalse);
      expect(logoutCalled, isFalse);
    });

    test('should reuse same controller implicitly (behavior test)', () async {
      int first = 0;
      int second = 0;

      Event.i.streamOf<_LoginEvent>().listen((_) => first++);
      Event.i.streamOf<_LoginEvent>().listen((_) => second++);

      Event.emit(_LoginEvent('shared'));
      await Future<void>.delayed(Duration.zero);

      expect(first, equals(1));
      expect(second, equals(1));
    });

    test('should allow multiple emits for same event type', () async {
      int count = 0;
      Event.i.on<_LoginEvent>((_) => count++);

      Event.emit(_LoginEvent('a'));
      Event.emit(_LoginEvent('b'));
      Event.emit(_LoginEvent('c'));
      await Future<void>.delayed(Duration.zero);

      expect(count, equals(3));
    });

    test('should safely handle disposeAll() called multiple times', () {
      expect(() {
        Event.i.disposeAll();
        Event.i.disposeAll();
      }, returnsNormally);
    });
  });
}

final class _LoginEvent {
  final String user;
  const _LoginEvent(this.user);
}

final class _LogoutEvent {
  final String user;
  const _LogoutEvent(this.user);
}
