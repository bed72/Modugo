import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:modugo/src/injectors/injector.dart';

final class AsyncBind<T> {
  static final Map<Type, AsyncBind> _binds = {};

  Future<T>? _cachedFuture;

  final Type type = T;
  final bool isSingleton;
  final Future<T> Function(Injector i) factoryFunction;
  final Future<void> Function(T instance)? disposeAsync;

  AsyncBind(this.factoryFunction, {this.isSingleton = true, this.disposeAsync});

  Future<T> get instance async {
    if (!isSingleton) return await factoryFunction(Injector());

    if (_cachedFuture != null) return _cachedFuture!;

    _cachedFuture = factoryFunction(Injector());

    try {
      return await _cachedFuture!;
    } catch (_) {
      _cachedFuture = null;
      rethrow;
    }
  }

  static AsyncBind? getBindByType(Type type) => _binds[type];

  static void register<T>(AsyncBind<T> bind) {
    _binds[bind.type] = bind;

    if (bind.isSingleton) {
      bind._cachedFuture = bind.factoryFunction(Injector());
    }
  }

  static Future<void> clearAll() async {
    for (final bind in _binds.values) {
      await bind.disposeInstance();
    }

    _binds.clear();
  }

  static Future<void> disposeByType(Type type) async {
    final bind = _binds[type];

    if (bind != null) await bind.disposeInstance();

    _binds.remove(type);
  }

  static Future<T> get<T>() async {
    final bind = _binds[T];

    if (bind == null) {
      throw Exception('AsyncBind not found for type ${T.toString()}');
    }

    return await (bind as AsyncBind<T>).instance;
  }

  Future<void> disposeInstance() async {
    if (!isSingleton || _cachedFuture == null) return;

    final instance = await _cachedFuture!;

    try {
      if (disposeAsync != null) {
        await disposeAsync!(instance);
      } else {
        if (instance is Sink) instance.close();
        if (instance is ChangeNotifier) instance.dispose();
        if (instance is StreamController) instance.close();
      }
    } catch (e, stack) {
      debugPrint(
        'Error disposing async instance of type ${instance.runtimeType}: $e',
      );
      debugPrint('$stack');
    }

    _cachedFuture = null;
  }
}
