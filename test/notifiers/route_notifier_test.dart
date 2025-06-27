import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/notifiers/router_notifier.dart';

import 'package:modugo/src/routes/events/route_action_event.dart';
import 'package:modugo/src/routes/events/route_change_event.dart';

void main() {
  group('RouteNotifier', () {
    test('initial value uses default event', () {
      final notifier = RouteNotifier();

      expect(notifier.value.current, '/');
      expect(notifier.value.previous, '/');
      expect(notifier.value.action, RouteActionEvent.push);
    });

    test('update with different current triggers notification', () {
      final notifier = RouteNotifier();
      bool notified = false;

      notifier.addListener(() {
        notified = true;
      });

      notifier.update(
        const RouteChangeEvent(
          previous: '/',
          current: '/details',
          action: RouteActionEvent.push,
        ),
      );

      expect(notified, isTrue);
      expect(notifier.value.previous, '/');
      expect(notifier.value.current, '/details');
      expect(notifier.value.action, RouteActionEvent.push);
    });

    test('update with same current does not notify', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      notifier.update(
        const RouteChangeEvent(
          previous: '/',
          current: '/',
          action: RouteActionEvent.redirect,
        ),
      );

      expect(notifyCount, equals(0));
      expect(notifier.value.action, isNot(RouteActionEvent.redirect));
    });

    test('multiple updates trigger only on current change', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.update(
        const RouteChangeEvent(
          previous: '/',
          current: '/',
          action: RouteActionEvent.push,
        ),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(
          previous: '/',
          current: '/a',
          action: RouteActionEvent.push,
        ),
      ); // notify

      notifier.update(
        const RouteChangeEvent(
          current: '/a',
          previous: '/a',
          action: RouteActionEvent.pop,
        ),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(
          current: '/b',
          previous: '/a',
          action: RouteActionEvent.redirect,
        ),
      ); // notify

      expect(notifyCount, equals(2));
      expect(notifier.value.current, '/b');
      expect(notifier.value.previous, '/a');
      expect(notifier.value.action, RouteActionEvent.redirect);
    });
  });
}
