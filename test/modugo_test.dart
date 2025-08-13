import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/notifiers/router_notifier.dart';
import 'package:modugo/src/extensions/context_injection_extension.dart';

void main() {
  test('configure sets router and registers binds', () async {
    final module = _InnerModule();
    final router = await Modugo.configure(module: module);

    expect(router, isA<GoRouter>());
    expect(() => Modugo.get<_Service>(), returnsNormally);
  });

  test('get<T>() retrieves registered dependency', () async {
    final module = _InnerModule();
    await Modugo.configure(module: module);

    final instance = Modugo.get<_Service>();
    expect(instance.value, 1);
  });

  test('configure does not recreate router if already set', () async {
    final module = _InnerModule();
    final first = await Modugo.configure(module: module);
    final second = await Modugo.configure(module: module);

    expect(identical(first, second), isTrue);
  });

  test('manager getter returns singleton instance', () {
    final m1 = Modugo.manager;
    final m2 = Modugo.manager;
    expect(identical(m1, m2), isTrue);
  });

  group('Modugo.routeNotifier integration', () {
    test('routeNotifier has default value "/"', () {
      final notifier = RouteNotifier();
      expect(notifier.value, '/');
    });

    test('does not notify on identical current route', () {
      final notifier = RouteNotifier();
      int callCount = 0;

      notifier.addListener(() => callCount++);

      notifier.update = '/';

      expect(callCount, equals(0));
    });

    test('notifies only when current route changes', () {
      final notifier = RouteNotifier();
      int count = 0;

      notifier.addListener(() => count++);

      notifier.update = '/initial'; // notify
      notifier.update = '/initial'; // no notify
      notifier.update = '/next'; // notify
      notifier.update = '/next'; // no notify
      notifier.update = '/final'; // notify

      expect(count, equals(3));
      expect(notifier.value, equals('/final'));
    });
  });
}

final class _Service {
  final int value = 1;
}

final class _InnerModule extends Module {
  @override
  void binds() {
    i.registerSingleton<_Service>(_Service());
  }

  @override
  List<IModule> routes() => [
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
