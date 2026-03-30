import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/mixins/event_mixin.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

void main() {
  group('IEvent.on autoDispose behavior', () {
    setUp(() => Event.i.disposeAll());
    tearDown(() => Event.i.disposeAll());

    test(
      'autoDispose: true (default) — subscription cancelled on dispose',
      () async {
        bool called = false;
        final module = _TestModule();
        module.on<_Evt>((_) => called = true, autoDispose: true);

        module.dispose();

        Event.emit(_Evt());
        await Future<void>.delayed(Duration.zero);

        expect(called, isFalse);
      },
    );

    test(
      'autoDispose: false — subscription still fires after module dispose',
      () async {
        bool called = false;
        final module = _TestModule();
        // Caller holds no reference — subscription is not tracked by module.
        module.on<_Evt>((_) => called = true, autoDispose: false);

        // Disposing the module does NOT cancel the subscription.
        module.dispose();

        Event.emit(_Evt());
        await Future<void>.delayed(Duration.zero);

        // The subscription is still alive — caller must cancel manually.
        expect(
          called,
          isTrue,
          reason:
              'autoDispose:false subscription is not cancelled by module.dispose()',
        );
      },
    );

    test('autoDispose: false — on() returns a valid StreamSubscription', () {
      final module = _TestModule();

      final sub = module.on<_Evt>((_) {}, autoDispose: false);

      expect(sub, isA<StreamSubscription<_Evt>>());
      sub.cancel();
    });
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
