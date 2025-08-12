import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';
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

  final T Function(IInjector i) _builder;

  /// Creates a [SingletonBind] with the given factory function.
  SingletonBind(this._builder);

  /// Returns the cached singleton instance of [T].
  ///
  /// If the instance does not exist yet, it is created and stored.
  @override
  T get(IInjector i) => _instance ??= _builder(i);

  /// Disposes of the stored instance, if any.
  ///
  /// If the instance implements [Sink], [ChangeNotifier], [StreamController],
  /// or has a `dispose()` method, appropriate cleanup is attempted.
  ///
  /// Errors during disposal are logged for debugging.
  @override
  void dispose() {
    final instance = _instance;
    if (instance == null) return;
    
    try {
      // Handle common Flutter/Dart disposable types
      if (instance is Sink) {
        instance.close();
      } else if (instance is ChangeNotifier) {
        instance.dispose();
      } else if (instance is StreamController) {
        instance.close();
      } else {
        // Try to call dispose() method if it exists
        _tryCallDispose(instance);
      }
      _instance = null;
    } catch (e, stack) {
      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $e',
      );
      Logger.error('$stack');
    }
  }

  /// Attempts to call dispose() method on the instance using reflection.
  void _tryCallDispose(dynamic instance) {
    try {
      // Try to access dispose method dynamically
      final disposeMethod = instance.dispose;
      if (disposeMethod != null && disposeMethod is Function) {
        disposeMethod();
      }
    } catch (e) {
      // If dispose method doesn't exist or fails, ignore silently
      // This allows objects without dispose method to be cleaned up normally
    }
  }
}
