import 'package:flutter_test/flutter_test.dart';
import 'package:modugo/src/notifiers/router_notifier.dart';

void main() {
  group('RouteNotifier', () {
    test('initial value is root route', () {
      final notifier = RouteNotifier();

      expect(notifier.value, '/');
    });

    test('update with different route triggers notification', () {
      final notifier = RouteNotifier();
      bool notified = false;

      notifier.addListener(() {
        notified = true;
      });

      notifier.update = '/details';

      expect(notified, isTrue);
      expect(notifier.value, '/details');
    });

    test('update with same route does not notify', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      notifier.update = '/';

      expect(notifyCount, equals(0));
    });

    test('multiple updates only notify on route change', () {
      final notifier = RouteNotifier();
      int notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.update = '/'; // no notify
      notifier.update = '/a'; // notify
      notifier.update = '/a'; // no notify
      notifier.update = '/b'; // notify

      expect(notifyCount, equals(2));
      expect(notifier.value, '/b');
    });
  });
}
