import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/context_injection_extension.dart';

void main() {
  setUp(() {
    GetIt.I.reset();
  });

  group('ContextInjectionExtension - read', () {
    testWidgets('should retrieve registered singleton', (tester) async {
      GetIt.I.registerSingleton<_Service>(_Service('test'));

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

    testWidgets('should retrieve named instance', (tester) async {
      GetIt.I.registerSingleton<_Service>(
        _Service('primary'),
        instanceName: 'primary',
      );
      GetIt.I.registerSingleton<_Service>(
        _Service('secondary'),
        instanceName: 'secondary',
      );

      late _Service primary;
      late _Service secondary;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            primary = context.read<_Service>(instanceName: 'primary');
            secondary = context.read<_Service>(instanceName: 'secondary');
            return const SizedBox();
          },
        ),
      );

      expect(primary.name, 'primary');
      expect(secondary.name, 'secondary');
    });

    testWidgets('should throw when service is not registered', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => context.read<_Service>(), throwsA(isA<Error>()));
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('ContextInjectionExtension - readAsync', () {
    testWidgets('should retrieve async registered singleton', (tester) async {
      GetIt.I.registerSingletonAsync<_Service>(() async => _Service('async'));

      await GetIt.I.allReady();

      late _Service result;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            context.readAsync<_Service>().then((s) => result = s);
            return const SizedBox();
          },
        ),
      );

      await tester.pump();
      expect(result.name, 'async');
    });
  });
}

final class _Service {
  _Service(this.name);

  final String name;
}
