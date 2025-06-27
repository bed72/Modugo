import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/notifiers/router_notifier.dart';

import 'package:modugo/src/routes/events/route_change_event.dart';

void main() {
  group('RouteNotifier', () {
    test('initial value uses default event', () {
      final notifier = RouteNotifier();

      expect(notifier.value.current, '/');
      expect(notifier.value.previous, '/');
    });

    test('update with different current triggers notification', () {
      final notifier = RouteNotifier();
      bool notified = false;

      notifier.addListener(() {
        notified = true;
      });

      notifier.update(
        const RouteChangeEvent(previous: '/', current: '/details'),
      );

      expect(notified, isTrue);
      expect(notifier.value.previous, '/');
      expect(notifier.value.current, '/details');
    });

    test('update with same current does not notify', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      notifier.update(const RouteChangeEvent(previous: '/', current: '/'));

      expect(notifyCount, equals(0));
    });

    test('multiple updates trigger only on current change', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.update(
        const RouteChangeEvent(previous: '/', current: '/'),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(previous: '/', current: '/a'),
      ); // notify

      notifier.update(
        const RouteChangeEvent(current: '/a', previous: '/a'),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(current: '/b', previous: '/a'),
      ); // notify

      expect(notifyCount, equals(2));
      expect(notifier.value.current, '/b');
      expect(notifier.value.previous, '/a');
    });
  });
}
