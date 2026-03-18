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

    test('slideUp begins at bottom (offset 0, 1)', () {
      final builder = Transition.builder(
        type: TypeTransition.slideUp,
        config: () {},
      );

      final transition =
          builder(
                _FakeBuildContext(),
                animation,
                secondaryAnimation,
                const SizedBox(),
              )
              as SlideTransition;

      // Verify by inspecting the builder's initial offset via the Tween begin.
      // The position animation should produce values starting from (0, 1).
      controller.value = 0; // animation at start
      final offset = transition.position.value;
      expect(offset.dx, closeTo(0.0, 0.01));
      expect(offset.dy, closeTo(1.0, 0.01)); // comes from bottom
    });

    test('slideDown begins at top (offset 0, -1)', () {
      final builder = Transition.builder(
        type: TypeTransition.slideDown,
        config: () {},
      );

      final transition =
          builder(
                _FakeBuildContext(),
                animation,
                secondaryAnimation,
                const SizedBox(),
              )
              as SlideTransition;

      controller.value = 0;
      final offset = transition.position.value;
      expect(offset.dx, closeTo(0.0, 0.01));
      expect(offset.dy, closeTo(-1.0, 0.01)); // comes from top
    });

    test('slideLeft begins at right (offset 1, 0)', () {
      final builder = Transition.builder(
        type: TypeTransition.slideLeft,
        config: () {},
      );

      final transition =
          builder(
                _FakeBuildContext(),
                animation,
                secondaryAnimation,
                const SizedBox(),
              )
              as SlideTransition;

      controller.value = 0;
      final offset = transition.position.value;
      expect(offset.dx, closeTo(1.0, 0.01)); // comes from right
      expect(offset.dy, closeTo(0.0, 0.01));
    });

    test('slideRight begins at left (offset -1, 0)', () {
      final builder = Transition.builder(
        type: TypeTransition.slideRight,
        config: () {},
      );

      final transition =
          builder(
                _FakeBuildContext(),
                animation,
                secondaryAnimation,
                const SizedBox(),
              )
              as SlideTransition;

      controller.value = 0;
      final offset = transition.position.value;
      expect(offset.dx, closeTo(-1.0, 0.01)); // comes from left
      expect(offset.dy, closeTo(0.0, 0.01));
    });

    test('all slides animate to Offset.zero at end', () {
      for (final type in [
        TypeTransition.slideUp,
        TypeTransition.slideDown,
        TypeTransition.slideLeft,
        TypeTransition.slideRight,
      ]) {
        final builder = Transition.builder(type: type, config: () {});
        final transition =
            builder(
                  _FakeBuildContext(),
                  animation,
                  secondaryAnimation,
                  const SizedBox(),
                )
                as SlideTransition;

        controller.value = 1; // animation at end
        final offset = transition.position.value;
        expect(offset, equals(Offset.zero), reason: '$type should end at zero');
      }
    });

    test(
      'TypeTransition.native falls back to FadeTransition in Transition.builder',
      () {
        // TypeTransition.native is handled at the page level (FactoryRoute),
        // not in Transition.builder. If it somehow reaches the builder, it falls
        // back to FadeTransition.
        final builder = Transition.builder(
          type: TypeTransition.native,
          config: () {},
        );

        final widget = builder(
          _FakeBuildContext(),
          animation,
          secondaryAnimation,
          const SizedBox(),
        );

        expect(widget, isA<FadeTransition>());
      },
    );

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
