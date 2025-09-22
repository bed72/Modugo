import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/transition.dart';

void main() {
  late bool configCalled;

  setUp(() {
    configCalled = false;
  });

  Widget buildTransitionWidget(TypeTransition type) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          final animation = AlwaysStoppedAnimation<double>(1.0);
          final transitionBuilder = Transition.builder(
            type: type,
            config: () {
              configCalled = true;
            },
          );

          return transitionBuilder(
            context,
            animation,
            animation,
            const Placeholder(key: Key('child')),
          );
        },
      ),
    );
  }

  testWidgets('calls config callback', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.fade));
    expect(configCalled, isTrue);
  });

  testWidgets('returns FadeTransition for fade type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.fade));

    expect(find.byType(FadeTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns ScaleTransition for scale type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.scale));

    expect(find.byType(ScaleTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns RotationTransition for rotation type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.rotation));

    expect(find.byType(RotationTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns SlideTransition for slideUp type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.slideUp));

    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns SlideTransition for slideDown type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.slideDown));

    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns SlideTransition for slideLeft type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.slideLeft));

    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('returns SlideTransition for slideRight type', (tester) async {
    await tester.pumpWidget(buildTransitionWidget(TypeTransition.slideRight));

    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byKey(const Key('child')), findsOneWidget);
  });
}
