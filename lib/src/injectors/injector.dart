import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:modugo/src/injectors/async_injector.dart';
import 'package:modugo/src/injectors/sync_injector.dart';

base class Injector {
  T getSync<T>() => SyncBind.get<T>();
  Future<T> getAsync<T>() => AsyncBind.get<T>();
}

void safeDispose(dynamic instance) {
  try {
    if (instance is Sink) instance.close();
    if (instance is ChangeNotifier) instance.dispose();
    if (instance is StreamController) instance.close();
  } catch (e, stack) {
    debugPrint('Error disposing instance of type ${instance.runtimeType}: $e');
    debugPrint('$stack');
  }
}

abstract interface class BaseBind<T> {
  final bool isSingleton;
  final T Function(Injector i) factoryFunction;

  BaseBind(this.factoryFunction, {this.isSingleton = true});

  FutureOr<T> getInstance();

  FutureOr<void> disposeInstance();

  Type get runtimeTypeKey => T;
}
