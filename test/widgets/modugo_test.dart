import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

void main() {
  group('Modugo.routeNotifier integration', () {
    testWidgets('routeNotifier emits location changes correctly', (
      tester,
    ) async {
      await Modugo.configure(module: _DummyModule(), initialRoute: '/');

      final notifier = Modugo.routeNotifier;

      String? lastLocation;

      notifier.addListener(() {
        lastLocation = notifier.value;
      });

      notifier.update = '/details';

      await tester.pump();

      expect(lastLocation, isNotNull);
      expect(lastLocation, '/details');
      expect(notifier.value, equals(lastLocation));
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
