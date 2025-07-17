import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/modugo.dart';

void main() {
  group('ExternalStackController', () {
    late ModugoStackController controller;

    setUp(() {
      controller = ModugoStackController.instance;
      controller.clear();
    });

    test('push adds new route to stack', () {
      controller.push('/home');
      expect(controller.stack, ['/home']);
    });

    test('push does not add duplicate consecutive route', () {
      controller.push('/home');
      controller.push('/home');
      expect(controller.stack.length, 1);
    });

    test('stack does not exceed 20 items', () {
      for (int i = 0; i < 25; i++) {
        controller.push('/route_$i');
      }
      expect(controller.stack.length, 20);
      expect(controller.stack.first, '/route_5');
    });

    test('pop returns the last route and removes it', () {
      controller.push('/a');
      controller.push('/b');
      final popped = controller.pop();
      expect(popped, '/b');
      expect(controller.stack, ['/a']);
    });

    test('pop returns null if stack is empty', () {
      final popped = controller.pop();
      expect(popped, isNull);
    });

    test('clear removes all routes', () {
      controller.push('/home');
      controller.clear();
      expect(controller.stack, isEmpty);
    });

    test('canPop returns true when stack is not empty', () {
      controller.push('/home');
      expect(controller.canPop, isTrue);
    });

    test('canPop returns false when stack is empty', () {
      expect(controller.canPop, isFalse);
    });

    test('stack returns an unmodifiable list', () {
      controller.push('/test');
      final stack = controller.stack;
      expect(() => stack.add('/illegal'), throwsUnsupportedError);
    });

    test('adds new paths and preserves existing ones', () {
      controller.stack = ['/home', '/cart'];
      controller.stack = ['/cart', '/profile'];

      expect(controller.stack, ['/home', '/cart', '/profile']);
    });

    test('does not add duplicates already in stack', () {
      controller.stack = ['/home', '/cart'];
      controller.stack = ['/home'];

      expect(controller.stack, ['/home', '/cart']);
    });

    test('preserves order of first occurrence only', () {
      controller.stack = ['/a', '/b'];
      controller.stack = ['/b', '/c', '/a', '/d'];

      expect(controller.stack, ['/a', '/b', '/c', '/d']);
    });

    test('works with empty initial stack', () {
      controller.stack = ['/x', '/y'];
      expect(controller.stack, ['/x', '/y']);
    });

    test('does not modify stack if all paths are already present', () {
      controller.stack = ['/home', '/cart'];
      final before = List<String>.from(controller.stack);
      controller.stack = ['/home', '/cart'];

      expect(controller.stack, before);
    });
  });
}
