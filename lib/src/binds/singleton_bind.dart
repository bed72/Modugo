import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

final class SingletonBind<T> implements IBind<T> {
  T? _instance;

  final T Function(Injector i) _builder;

  SingletonBind(this._builder);

  @override
  T get(Injector i) => _instance ??= _builder(i);

  @override
  void dispose() {
    final instance = _instance;
    try {
      if (instance is Sink) instance.close();
      if (instance is ChangeNotifier) instance.dispose();
      if (instance is StreamController) instance.close();
      _instance = null;
    } catch (e, stack) {
      if (Modugo.debugLogDiagnostics) {
        ModugoLogger.info(
          '[SINGLETON] Error disposing instance of type ${instance.runtimeType}: $e',
        );
        ModugoLogger.error('$stack');
      }
    }
  }
}
