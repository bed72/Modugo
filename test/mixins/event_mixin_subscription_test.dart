import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/mixins/event_mixin.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

void main() {
  setUp(() => Event.i.disposeAll());
  tearDown(() => Event.i.disposeAll());

  // 3.1
  test(
    'autoDispose: true — subscription cancelled on dispose, callback not called',
    () async {
      bool called = false;
      final module = _TestModule();
      module.on<_Evt>((_) => called = true);

      module.dispose();

      Event.emit(_Evt());
      await Future<void>.delayed(Duration.zero);

      expect(called, isFalse);
    },
  );

  // 3.2
  test(
    'autoDispose: false — on<T>() returns non-null StreamSubscription<T>',
    () {
      final module = _TestModule();
      final sub = module.on<_Evt>((_) {}, autoDispose: false);

      expect(sub, isNotNull);
      expect(sub, isA<StreamSubscription<_Evt>>());
      sub.cancel();
    },
  );

  // 3.3
  test('autoDispose: false — returned subscription can be cancelled manually; '
      'callback not called after manual cancel', () async {
    bool called = false;
    final module = _TestModule();
    final sub = module.on<_Evt>((_) => called = true, autoDispose: false);

    await sub.cancel();

    Event.emit(_Evt());
    await Future<void>.delayed(Duration.zero);

    expect(called, isFalse);
  });

  // 3.4
  test(
    'autoDispose: false — module.dispose() does NOT cancel the subscription; '
    'callback still active after module dispose',
    () async {
      bool called = false;
      final module = _TestModule();
      final sub = module.on<_Evt>((_) => called = true, autoDispose: false);

      module.dispose();

      Event.emit(_Evt());
      await Future<void>.delayed(Duration.zero);

      expect(called, isTrue);
      await sub.cancel();
    },
  );

  // 3.5
  test(
    'multiple autoDispose: true subscriptions — all cancelled on dispose',
    () async {
      int callCount = 0;
      final module = _TestModule();

      module.on<_Evt>((_) => callCount++);
      module.on<_Evt>((_) => callCount++);
      module.on<_Evt>((_) => callCount++);

      module.dispose();

      Event.emit(_Evt());
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 0);
    },
  );

  // 3.6
  test(
    'multiple autoDispose: false — each returned subscription is independent '
    'and cancellable',
    () async {
      int callCount = 0;
      final module = _TestModule();

      final sub1 = module.on<_Evt>((_) => callCount++, autoDispose: false);
      final sub2 = module.on<_Evt>((_) => callCount++, autoDispose: false);
      final sub3 = module.on<_Evt>((_) => callCount++, autoDispose: false);

      // Cancel only sub2
      await sub2.cancel();

      Event.emit(_Evt());
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 2); // sub1 and sub3 still active

      await sub1.cancel();
      await sub3.cancel();
    },
  );

  // 3.7
  test('ignoring return of on<T>(autoDispose: true) — no compiler warning, '
      'behavior identical to previous void return', () async {
    bool called = false;
    final module = _TestModule();

    // Return value deliberately ignored — must behave exactly as before.
    // ignore: unused_local_variable
    module.on<_Evt>((_) => called = true);

    Event.emit(_Evt());
    await Future<void>.delayed(Duration.zero);

    expect(called, isTrue);

    module.dispose();
  });

  // 3.8
  test('after module.dispose(), new Event.emit does not reach autoDispose:true '
      'listeners', () async {
    int callCount = 0;
    final module = _TestModule();
    module.on<_Evt>((_) => callCount++);

    module.dispose();

    Event.emit(_Evt());
    Event.emit(_Evt());
    await Future<void>.delayed(Duration.zero);

    expect(callCount, 0);
  });

  // 3.9
  test('after module.dispose(), new Event.emit still reaches autoDispose:false '
      'listeners that were not manually cancelled', () async {
    int callCount = 0;
    final module = _TestModule();
    final sub = module.on<_Evt>((_) => callCount++, autoDispose: false);

    module.dispose();

    Event.emit(_Evt());
    Event.emit(_Evt());
    await Future<void>.delayed(Duration.zero);

    expect(callCount, 2);
    await sub.cancel();
  });
}

final class _Evt {
  const _Evt();
}

final class _TestModule extends Module with IEvent {
  @override
  void listen() {}

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}
