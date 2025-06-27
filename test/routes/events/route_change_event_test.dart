import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/events/route_change_event.dart';

void main() {
  test('equality: identical fields should be equal', () {
    final a = RouteChangeEvent(previous: '/home', current: '/details');
    final b = RouteChangeEvent(previous: '/home', current: '/details');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('equality: the same event', () {
    final a = RouteChangeEvent(previous: '/home', current: '/details');
    final b = RouteChangeEvent(previous: '/home', current: '/details');

    expect(a, equals(b));
  });

  test('equality: different current should not be equal', () {
    final a = RouteChangeEvent(previous: '/home', current: '/details');
    final b = RouteChangeEvent(previous: '/home', current: '/settings');

    expect(a, isNot(equals(b)));
  });

  test('toString should be descriptive', () {
    final event = RouteChangeEvent(previous: '/home', current: '/details');

    expect(event.toString(), contains('/home'));
    expect(event.toString(), contains('/details'));
    expect(event.toString(), contains('RouteChangeEvent'));
  });
}
