import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/events/route_action_event.dart';
import 'package:modugo/src/routes/events/route_change_event.dart';

void main() {
  test('equality: identical fields should be equal', () {
    final a = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.push,
    );
    final b = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.push,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('equality: different action should not be equal', () {
    final a = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.push,
    );
    final b = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.replace,
    );

    expect(a, isNot(equals(b)));
  });

  test('equality: different current should not be equal', () {
    final a = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.push,
    );
    final b = RouteChangeEvent(
      previous: '/home',
      current: '/settings',
      action: RouteActionEvent.push,
    );

    expect(a, isNot(equals(b)));
  });

  test('toString should be descriptive', () {
    final event = RouteChangeEvent(
      previous: '/home',
      current: '/details',
      action: RouteActionEvent.push,
    );

    expect(event.toString(), contains('push'));
    expect(event.toString(), contains('/home'));
    expect(event.toString(), contains('/details'));
    expect(event.toString(), contains('RouteChangeEvent'));
  });
}
