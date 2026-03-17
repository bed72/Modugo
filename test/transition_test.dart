import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/transition.dart';

void main() {
  group('TypeTransition - enum values', () {
    test('should have all expected transition types', () {
      expect(TypeTransition.values, hasLength(8));
      expect(TypeTransition.values, contains(TypeTransition.fade));
      expect(TypeTransition.values, contains(TypeTransition.scale));
      expect(TypeTransition.values, contains(TypeTransition.slideUp));
      expect(TypeTransition.values, contains(TypeTransition.slideDown));
      expect(TypeTransition.values, contains(TypeTransition.slideLeft));
      expect(TypeTransition.values, contains(TypeTransition.slideRight));
      expect(TypeTransition.values, contains(TypeTransition.rotation));
      expect(TypeTransition.values, contains(TypeTransition.native));
    });
  });

  group('Transition.builder', () {
    late AnimationController controller;
    late Animation<double> animation;
    late Animation<double> secondaryAnimation;

    setUp(() {
      controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      animation = controller;
      secondaryAnimation = kAlwaysDismissedAnimation;
    });

    tearDown(() {
      controller.dispose();
    });

    test('should call config callback', () {
      var configCalled = false;

      final builder = Transition.builder(
        type: TypeTransition.fade,
        config: () => configCalled = true,
      );

      builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(configCalled, isTrue);
    });

    test('should return FadeTransition for fade type', () {
      final builder = Transition.builder(
        type: TypeTransition.fade,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<FadeTransition>());
    });

    test('should return ScaleTransition for scale type', () {
      final builder = Transition.builder(
        type: TypeTransition.scale,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<ScaleTransition>());
    });

    test('should return SlideTransition for slideUp type', () {
      final builder = Transition.builder(
        type: TypeTransition.slideUp,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<SlideTransition>());
    });

    test('should return SlideTransition for slideDown type', () {
      final builder = Transition.builder(
        type: TypeTransition.slideDown,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<SlideTransition>());
    });

    test('should return SlideTransition for slideLeft type', () {
      final builder = Transition.builder(
        type: TypeTransition.slideLeft,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<SlideTransition>());
    });

    test('should return SlideTransition for slideRight type', () {
      final builder = Transition.builder(
        type: TypeTransition.slideRight,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<SlideTransition>());
    });

    test('should return RotationTransition for rotation type', () {
      final builder = Transition.builder(
        type: TypeTransition.rotation,
        config: () {},
      );

      final widget = builder(
        _FakeBuildContext(),
        animation,
        secondaryAnimation,
        const SizedBox(),
      );

      expect(widget, isA<RotationTransition>());
    });
  });
}

final class _FakeBuildContext extends Fake implements BuildContext {}
