import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/mixins/event_mixin.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/routes/child_route.dart';

/// Documents DESIGN-14: `IEvent.on<T>(autoDispose: false)` creates a
/// StreamSubscription that is neither stored nor returned. Once registered,
/// there is no API to cancel it — it is an irrecoverable resource leak.
///
/// These tests document the current behavior. When DESIGN-14 is addressed
/// (e.g., by returning the StreamSubscription), the leak test should be updated.
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
      '[DESIGN-14] autoDispose: false — subscription still fires after module dispose',
      () async {
        bool called = false;
        final module = _TestModule();
        module.on<_Evt>((_) => called = true, autoDispose: false);

        // Disposing the module does NOT cancel the subscription.
        module.dispose();

        Event.emit(_Evt());
        await Future<void>.delayed(Duration.zero);

        // The subscription is still alive — this is the documented leak.
        expect(
          called,
          isTrue,
          reason:
              'DESIGN-14: autoDispose:false subscription cannot be cancelled',
        );
      },
    );

    test(
      '[DESIGN-14] autoDispose: false — on() returns void, caller cannot cancel',
      () {
        final module = _TestModule();

        // on() returns void — the caller has no handle to cancel the subscription.
        // This documents the API limitation: no way to clean up.
        expect(
          () => module.on<_Evt>((_) {}, autoDispose: false),
          returnsNormally,
        );
      },
    );
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
