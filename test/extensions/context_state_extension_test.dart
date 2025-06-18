import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_state_extension.dart';

void main() {
  testWidgets('ContextStateExtension accessors work correctly', (tester) async {
    final router = GoRouter(
      initialLocation: '/product/42?show=true&count=5',
      routes: [
        GoRoute(
          path: '/product/:id',
          name: 'product',
          builder: (context, state) {
            return _Dummy(state);
          },
        ),
      ],
      redirect: (_, __) => null,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_Dummy));

    expect(context.path, '/product/:id');
    expect(context.locationSegments, ['product', '42']);

    expect(context.getPathParam('id'), '42');

    expect(context.getStringQueryParam('count'), '5');
    expect(context.getIntQueryParam('count'), 5);
    expect(context.getBoolQueryParam('show'), isTrue);
    expect(context.getBoolQueryParam('missing'), isNull);

    expect(context.isInitialRoute, isFalse);

    expect(context.isCurrentRoute('product'), isTrue);
    expect(context.isCurrentRoute('home'), isFalse);
  });

  testWidgets('getExtra and argumentsOrThrow work', (tester) async {
    final router = GoRouter(
      initialLocation: '/next',
      routes: [
        GoRoute(
          path: '/next',
          name: 'next',
          builder: (context, state) => _Dummy(state),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/next', extra: _Payload('modugo'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_Dummy));

    final extra = context.getExtra<_Payload>();
    expect(extra?.value, 'modugo');

    expect(context.argumentsOrThrow<_Payload>().value, 'modugo');

    expect(() => context.argumentsOrThrow<String>(), throwsException);
  });
}

final class _Dummy extends StatelessWidget {
  final GoRouterState state;
  const _Dummy(this.state);

  @override
  Widget build(BuildContext context) =>
      Text('dummy', textDirection: TextDirection.ltr);
}

final class _Payload {
  final String value;
  const _Payload(this.value);
}
