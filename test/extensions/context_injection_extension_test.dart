import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/extensions/context_injection_extension.dart';

void main() {
  setUp(() {
    Modugo.container.disposeAll();
  });

  group('ContextInjectionExtension - read', () {
    testWidgets('should retrieve registered singleton', (tester) async {
      Modugo.container.addSingleton<_Service>((c) => _Service('test'));

      late _Service result;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            result = context.read<_Service>();
            return const SizedBox();
          },
        ),
      );

      expect(result.name, 'test');
    });

    testWidgets('should throw when service is not registered', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => context.read<_Service>(),
              throwsA(isA<StateError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('ContextInjectionExtension - tryRead', () {
    testWidgets('should return null when service is not registered',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final result = context.tryRead<_Service>();
            expect(result, isNull);
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('should return instance when registered', (tester) async {
      Modugo.container.addSingleton<_Service>((c) => _Service('found'));

      late _Service? result;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            result = context.tryRead<_Service>();
            return const SizedBox();
          },
        ),
      );

      expect(result, isNotNull);
      expect(result!.name, 'found');
    });
  });
}

final class _Service {
  _Service(this.name);

  final String name;
}
