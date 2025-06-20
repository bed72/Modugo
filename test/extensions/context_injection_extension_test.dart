import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/extensions/context_injection_extension.dart';

void main() {
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
}

final class _Service {
  final String value;
  _Service(this.value);
}
