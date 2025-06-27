import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/events/route_change_event.dart';

void main() {
  group('Modugo.routeNotifier integration', () {
    testWidgets('routeNotifier emits RouteChangeEvent correctly', (
      tester,
    ) async {
      await Modugo.configure(module: _DummyModule(), initialRoute: '/');

      final notifier = Modugo.routeNotifier;

      RouteChangeEvent? lastEvent;

      notifier.addListener(() {
        lastEvent = notifier.value;
      });

      notifier.update(
        const RouteChangeEvent(previous: '/', current: '/details'),
      );

      await tester.pump();

      expect(lastEvent, isNotNull);
      expect(lastEvent!.previous, '/');
      expect(lastEvent!.current, '/details');

      expect(notifier.value, equals(lastEvent));
    });
  });
}

final class _DummyModule extends Module {
  @override
  List<IModule> get routes => [
    ChildRoute('/', child: (_, __) => const Placeholder()),
    ChildRoute('/details', child: (_, __) => const Placeholder()),
  ];
}
