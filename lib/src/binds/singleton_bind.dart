import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

/// A bind that creates and stores a **single instance** of a dependency
/// as soon as it is first requested — and keeps it in memory until disposal.
///
/// Unlike [LazySingletonBind], this does **not** delay instantiation intentionally;
/// the difference is subtle in behavior but identical in structure.
///
/// Example:
/// ```dart
/// Bind.singleton((i) => AppConfig());
/// ```
///
/// In this case, the first time `Injector.get<AppConfig>()` is called,
/// the `AppConfig` is created and stored. All future requests will return
/// the same instance.
///
/// The `dispose` method attempts to clean up common types:
/// - [Sink] → calls `close()`
/// - [ChangeNotifier] → calls `dispose()`
/// - [StreamController] → calls `close()`
///
/// Any errors during disposal are logged when [Modugo.debugLogDiagnostics] is enabled.
final class SingletonBind<T> implements IBind<T> {
  T? _instance;

  final T Function(Injector i) _builder;

  /// Creates a [SingletonBind] with the given factory function.
  SingletonBind(this._builder);

  /// Returns the cached singleton instance of [T].
  ///
  /// If the instance does not exist yet, it is created and stored.
  @override
  T get(Injector i) => _instance ??= _builder(i);

  /// Disposes of the stored instance, if any.
  ///
  /// If the instance implements [Sink], [ChangeNotifier], or [StreamController],
  /// appropriate cleanup is attempted.
  ///
  /// Errors during disposal are logged for debugging.
  @override
  void dispose() {
    final instance = _instance;
    try {
      if (instance is Sink) instance.close();
      if (instance is ChangeNotifier) instance.dispose();
      if (instance is StreamController) instance.close();
      _instance = null;
    } catch (e, stack) {
      ModugoLogger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $e',
      );
      ModugoLogger.error('$stack');
    }
  }
}
