import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/managers/queue_manager.dart';

void main() {
  test('QueueManager enqueues and processes operations sequentially', () async {
    final queue = QueueManager.instance;
    int counter = 0;

    await queue.enqueue(() async {
      await Future.delayed(Duration(milliseconds: 10));
      counter++;
    });

    await queue.enqueue(() async {
      await Future.delayed(Duration(milliseconds: 10));
      counter++;
    });

    expect(counter, 2);
  });

  group('QueueManager Singleton behavior', () {
    test('should return the same instance every time', () {
      final instance1 = QueueManager.instance;
      final instance2 = QueueManager.instance;

      expect(instance1, same(instance2));
    });
  });

  group('QueueManager enqueue operations', () {
    test('executes operations sequentially in order', () async {
      final results = <int>[];
      final queue = QueueManager.instance;

      await queue.enqueue(() async {
        await Future.delayed(Duration(milliseconds: 100));
        results.add(1);
      });

      await queue.enqueue(() async {
        results.add(2);
      });

      await queue.enqueue(() async {
        results.add(3);
      });

      expect(results, [1, 2, 3]);
    });

    test('returns the correct result from the operation', () async {
      final queue = QueueManager.instance;

      final result = await queue.enqueue(() async {
        await Future.delayed(Duration(milliseconds: 50));
        return 42;
      });

      expect(result, 42);
    });

    test('propagates errors thrown in the operation', () async {
      final queue = QueueManager.instance;

      final future = queue.enqueue<int>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        throw Exception('operation failed');
      });

      expect(future, throwsA(isA<Exception>()));
    });

    test('processes next operation only after previous completes', () async {
      final queue = QueueManager.instance;
      final order = <String>[];

      final completer = Completer<void>();

      final future1 = queue.enqueue(() async {
        order.add('start1');
        await completer.future;
        order.add('end1');
      });

      final future2 = queue.enqueue(() async {
        order.add('operation2');
      });

      await Future.delayed(Duration(milliseconds: 50));
      expect(order, ['start1']);

      completer.complete();
      await future1;

      await future2;

      expect(order, ['start1', 'end1', 'operation2']);
    });
  });
}
