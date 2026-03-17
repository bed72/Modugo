import 'package:flutter/widgets.dart';

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/extensions/context_injection_extension.dart';

/// Resets Modugo's internal singleton state between tests.
void _resetModugo() {
  Modugo.resetForTesting();
  GetIt.instance.reset();
}

void main() {
  tearDown(_resetModugo);

  test('configure sets router and registers binds', () async {
    final module = _InnerModule();
    final router = await Modugo.configure(module: module);

    expect(router, isA<GoRouter>());
    expect(() => Modugo.i.get<_Service>(), returnsNormally);
  });

  test('get<T>() retrieves registered dependency', () async {
    final module = _InnerModule();
    await Modugo.configure(module: module);

    final instance = Modugo.i.get<_Service>();
    expect(instance.value, 1);
  });

  test('configure does not recreate router if already set', () async {
    final module = _InnerModule();
    final first = await Modugo.configure(module: module);
    final second = await Modugo.configure(module: module);

    expect(identical(first, second), isTrue);
  });

  group('enableIOSGestureNavigation', () {
    test('defaults to true after configure()', () async {
      await Modugo.configure(module: _InnerModule());

      expect(Modugo.enableIOSGestureNavigation, isTrue);
    });

    test('persists false when configured explicitly', () async {
      await Modugo.configure(
        module: _InnerModule(),
        enableIOSGestureNavigation: false,
      );

      expect(Modugo.enableIOSGestureNavigation, isFalse);
    });
  });
}

final class _Service {
  final int value = 1;
}

final class _InnerModule extends Module {
  @override
  void binds() async {
    i.registerSingleton<_Service>(_Service());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(
      path: '/',
      name: 'home',
      child: (context, _) {
        final service = context.read<_Service>();

        return Text('value: ${service.value}');
      },
    ),
  ];
}
