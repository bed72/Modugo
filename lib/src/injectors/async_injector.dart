import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:modugo/src/injectors/injector.dart';

final class AsyncBind<T> {
  static final Map<Type, AsyncBind> _asyncBinds = {};

  Future<T>? _cachedFuture;

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
    } catch (e) {
      _cachedFuture = null;
      rethrow;
    }
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

  static Future<T> get<T>() async {
    final bind = _asyncBinds[T];
    if (bind == null) {
      throw Exception('AsyncBind not found for type ${T.toString()}');
    }
    return await (bind as AsyncBind<T>).instance;
  }

  static void register<T>(AsyncBind<T> bind) {
    _asyncBinds[T] = bind;

    if (bind.isSingleton) {
      bind._cachedFuture = bind.factoryFunction(Injector());
    }
  }

  static Future<void> disposeByType(Type type) async {
    final bind = _asyncBinds[type];
    if (bind != null) await bind.disposeInstance();
    _asyncBinds.remove(type);
  }

  static Future<void> clearAll() async {
    for (final bind in _asyncBinds.values) {
      await bind.disposeInstance();
    }
    _asyncBinds.clear();
  }
}
