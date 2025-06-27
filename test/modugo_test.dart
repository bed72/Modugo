import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/events/route_change_event.dart';

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
      expect(notifier.value.current, '/');
      expect(notifier.value.previous, '/');
    });

    test('does not notify on identical current route', () {
      final notifier = RouteNotifier();
      int callCount = 0;

      notifier.addListener(() => callCount++);

      notifier.update(
        const RouteChangeEvent(current: '/', previous: '/previous'),
      );

      expect(callCount, equals(0));
    });

    test('notifies only when current route changes', () {
      final notifier = RouteNotifier();
      int count = 0;

      notifier.addListener(() => count++);

      notifier.update(
        const RouteChangeEvent(previous: '/', current: '/initial'),
      ); // notify

      notifier.update(
        const RouteChangeEvent(previous: '/initial', current: '/initial'),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(previous: '/initial', current: '/next'),
      ); // notify

      notifier.update(
        const RouteChangeEvent(previous: '/next', current: '/next'),
      ); // no notify

      notifier.update(
        const RouteChangeEvent(previous: '/next', current: '/final'),
      ); // notify

      expect(count, equals(3));
      expect(notifier.value.current, equals('/final'));
    });
  });
}

final class _Service {
  final int value = 1;
}

final class _InnerModule extends Module {
  @override
  void binds(IInjector i) {
    i.addSingleton<_Service>((_) => _Service());
  }

  @override
  List<IModule> get routes => [
    ChildRoute(
      '/',
      name: 'home',
      child: (context, __) {
        final service = context.read<_Service>();

        return Text('value: ${service.value}');
      },
    ),
  ];
}
