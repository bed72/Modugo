import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:modugo/src/injectors/injector.dart';

final class AsyncBind<T> {
  static final Map<Type, AsyncBind> _binds = {};

  Future<T>? _cachedFuture;

  final Type type = T;
  final bool isSingleton;
  final List<Type> dependsOn;
  final Future<T> Function(Injector i) factoryFunction;
  final Future<void> Function(T instance)? disposeAsync;

  AsyncBind(
    this.factoryFunction, {
    this.disposeAsync,
    this.isSingleton = true,
    this.dependsOn = const [],
  });

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
  }

  static Future<void> registerAllWithDependencies(List<AsyncBind> binds) async {
    final queue = List<AsyncBind>.from(binds);
    final resolved = <Type>{};

    while (queue.isNotEmpty) {
      final bind = queue.removeAt(0);

      final allDepsMet = bind.dependsOn.every(resolved.contains);
      if (allDepsMet) {
        _binds[bind.type] = bind;

        if (bind.isSingleton) {
          try {
            await bind.instance;
          } catch (_) {
            _binds.remove(bind.type);
            rethrow;
          }
        }

        resolved.add(bind.type);
      } else {
        queue.add(bind); // Retry later
        if (queue.length == binds.length) {
          throw Exception(
            'Circular or unresolved async dependencies: ${queue.map((b) => b.type).toList()}',
          );
        }
      }
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
