import 'dart:async';

import 'package:flutter/material.dart';
import 'package:modugo/src/logger.dart';

base class Injector {
  static final Injector _instance = Injector._();

  Injector._();

  factory Injector() => _instance;

  T get<T>() => Bind.get<T>();
}

final class Bind<T> {
  static final Map<Type, Bind> _binds = {};

  T? _cachedInstance;

  final bool isLazy;
  final Type type = T;
  final bool isSingleton;
  final T Function(Injector i) factoryFunction;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = true});

  T? get maybeInstance => _cachedInstance;

  T get instance {
    if (!isSingleton) return factoryFunction(Injector());
    return _cachedInstance ??= factoryFunction(Injector());
  }

  static bool isRegistered<T>() => _binds.containsKey(T);

  static Bind? getBindByType(Type type) => _binds[type];

  static Bind<T> factory<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: false, isLazy: false);

  static Bind<T> singleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: false);

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: true);

  static void register<T>(Bind<T> bind) {
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
    final bind = _binds[T];

    if (bind == null) {
      throw Exception('Bind not found for type ${T.toString()}');
    }

    return (bind as Bind<T>).instance;
  }

  void disposeInstance() {
    if (!isSingleton || _cachedInstance == null) return;

    final instance = _cachedInstance;

    try {
      if (instance is Sink) instance.close();
      if (instance is ChangeNotifier) instance.dispose();
      if (instance is StreamController) instance.close();
    } catch (e, stack) {
      ModugoLogger.error(
        'Error disposing instance of type ${instance.runtimeType}: $e',
      );
      ModugoLogger.error('$stack');
    }

    _cachedInstance = null;
  }
}
