import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should not exit route when onExit returns false', (
    tester,
  ) async {
    final router = await Modugo.configure(
      module: _ModuleWithOnExitMock(),
      initialRoute: '/guarded',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/other');
    await tester.pumpAndSettle();

    expect(find.text('GuardedScreen'), findsOneWidget);
  });
}

final class _ModuleWithOnExitMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/guarded',
      name: 'guarded',
      child: (_, __) => const Text('GuardedScreen'),
      onExit: (_, __) => Future.value(false),
    ),
    ChildRoute(
      '/other',
      name: 'other',
      child: (_, __) => const Text('OtherScreen'),
    ),
  ];
}
