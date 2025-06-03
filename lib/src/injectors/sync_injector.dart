import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:modugo/src/injectors/injector.dart';

final class SyncBind<T> {
  static final Map<Type, SyncBind> _binds = {};

  T? _cachedInstance;

  final bool isLazy;
  final Type type = T;
  final bool isSingleton;
  final T Function(Injector i) factoryFunction;

  SyncBind(this.factoryFunction, {this.isSingleton = true, this.isLazy = true});

  T? get maybeInstance => _cachedInstance;

  T get instance {
    if (!isSingleton) return factoryFunction(Injector());
    return _cachedInstance ??= factoryFunction(Injector());
  }

  static SyncBind? getBindByType(Type type) => _binds[type];

  static SyncBind<T> factory<T>(T Function(Injector i) builder) =>
      SyncBind<T>(builder, isSingleton: false, isLazy: false);

  static SyncBind<T> singleton<T>(T Function(Injector i) builder) =>
      SyncBind<T>(builder, isSingleton: true, isLazy: false);

  static SyncBind<T> lazySingleton<T>(T Function(Injector i) builder) =>
      SyncBind<T>(builder, isSingleton: true, isLazy: true);

  static void register<T>(SyncBind<T> bind) {
    _binds[bind.type] = bind;

    if (!bind.isLazy && bind.isSingleton) {
      bind._cachedInstance = bind.factoryFunction(Injector());
    }
  }

  static void clearAll() {
    for (final bind in _binds.values) {
      bind.disposeInstance();
    }

    _binds.clear();
  }

  static void disposeByType(Type type) {
    final bind = _binds[type];

    if (bind != null && bind.isSingleton) bind.disposeInstance();

    _binds.remove(type);
  }

  static T get<T>() {
    {
      final bind = _binds[T];

      if (bind == null) {
        throw Exception('SyncBind not found for type ${T.toString()}');
      }

      return (bind as SyncBind<T>).instance;
    }
  }

  void disposeInstance() {
    if (!isSingleton || _cachedInstance == null) return;

    final instance = _cachedInstance;

    try {
      if (instance is Sink) instance.close();
      if (instance is ChangeNotifier) instance.dispose();
      if (instance is StreamController) instance.close();
    } catch (e, stack) {
      debugPrint(
        'Error disposing instance of type ${instance.runtimeType}: $e',
      );
      debugPrint('$stack');
    }

    _cachedInstance = null;
  }
}
