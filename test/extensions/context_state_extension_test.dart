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
          name: 'product',
          path: '/product/:id',
          builder: (_, state) {
            return _Dummy(state);
          },
        ),
      ],
      redirect: (_, _) => null,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(_Dummy));

    expect(context.path, '/product/42');
    expect(context.isInitialRoute, isFalse);
    expect(context.getPathParam('id'), '42');
    expect(context.getIntQueryParam('count'), 5);
    expect(context.isCurrentRoute('home'), isFalse);
    expect(context.isCurrentRoute('product'), isTrue);
    expect(context.getStringQueryParam('count'), '5');
    expect(context.getBoolQueryParam('show'), isTrue);
    expect(context.locationSegments, ['product', '42']);
    expect(context.getBoolQueryParam('missing'), isNull);
    expect(context.fullPath, '/product/42?show=true&count=5');
  });

  testWidgets('getExtra and argumentsOrThrow work', (tester) async {
    final router = GoRouter(
      initialLocation: '/next',
      routes: [
        GoRoute(
          name: 'next',
          path: '/next',
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

  testWidgets('buildPath builds correct url from pattern', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final path = context.buildPath('/produto/:id', {'id': 'X9'});
            return Text(path);
          },
        ),
      ),
    );

    expect(find.text('/produto/X9'), findsOneWidget);
  });

  testWidgets('buildPath throws if required param is missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            context.buildPath('/produto/:id', {});
            return const Placeholder();
          },
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<ArgumentError>());
    expect((exception as ArgumentError).message, contains('Expected key "id"'));
  });

  testWidgets('BuildContext.uri returns correct Uri', (tester) async {
    final router = GoRouter(
      initialLocation: '/test?query=value',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, state) => const Text('Test Page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    final context = tester.element(find.text('Test Page'));

    expect(context.uri.path, '/test');
    expect(context.fullPath, '/test?query=value');
    expect(context.uri.queryParameters['query'], 'value');
  });

  testWidgets('BuildContext.name returns route name if defined', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/named',
      routes: [
        GoRoute(
          path: '/named',
          name: 'namedRoute',
          builder: (context, state) => const Text('Named Page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    final context = tester.element(find.text('Named Page'));

    expect(context.name, 'namedRoute');
  });

  testWidgets('BuildContext.fullPath returns route path pattern', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/caneca-cafe/dp/7227D27',
      routes: [
        GoRoute(
          path: '/:name/dp/:webcode',
          builder: (context, state) => const Text('Product Page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    final context = tester.element(find.text('Product Page'));

    expect(context.path, '/caneca-cafe/dp/7227D27');
    expect(context.getPathParam('webcode'), '7227D27');
    expect(context.fullPath, '/caneca-cafe/dp/7227D27');
    expect(context.getPathParam('name'), 'caneca-cafe');
  });
}

final class _Dummy extends StatelessWidget {
  final GoRouterState state;
  const _Dummy(this.state);

  @override
  Widget build(BuildContext context) => Text('dummy');
}

final class _Payload {
  final String value;
  const _Payload(this.value);
}
