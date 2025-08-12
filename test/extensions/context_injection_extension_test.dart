import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/extensions/context_injection_extension.dart';

void main() {
  setUp(() {
    Injector().clearAll();
  });

  testWidgets('read<T>() retrieves instance from Injector', (tester) async {
    Injector().addSingleton<_Service>((_) => _Service('modugo'));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final service = context.read<_Service>();
            return Text(service.value);
          },
        ),
      ),
    );

    expect(find.text('modugo'), findsOneWidget);
  });

  testWidgets('read<T>(key:) retrieves keyed instance from Injector', (tester) async {
    Injector()
      ..addSingleton<_Service>((_) => _Service('primary'), key: 'primary')
      ..addSingleton<_Service>((_) => _Service('secondary'), key: 'secondary');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final primaryService = context.read<_Service>(key: 'primary');
            final secondaryService = context.read<_Service>(key: 'secondary');
            return Column(
              children: [
                Text(primaryService.value),
                Text(secondaryService.value),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('primary'), findsOneWidget);
    expect(find.text('secondary'), findsOneWidget);
  });
}

final class _Service {
  final String value;
  _Service(this.value);
}
