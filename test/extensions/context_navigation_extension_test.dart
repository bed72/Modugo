import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_navigation_extension.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('Home')),
        GoRoute(
          path: '/profile/:id',
          builder: (_, __) => const Text('Profile'),
        ),
      ],
    );
  });

  testWidgets('canPush returns true for valid route', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final context = tester.element(find.byType(Text));
    expect(context.canPush('/profile/123'), isTrue);
    expect(context.canPush('/invalid'), isFalse);
  });
}
