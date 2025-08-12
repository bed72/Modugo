import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

/// A bind that creates a **single instance** of a dependency,
/// but **only when it's first requested** (lazy instantiation).
///
/// This is useful for optimizing performance and memory usage,
/// especially for services that may not always be needed.
///
/// Example:
/// ```dart
/// Bind.lazySingleton((i) => AuthService());
/// ```
///
/// In this example, the `AuthService` will only be created when
/// `Injector.get<AuthService>()` is called for the first time.
///
/// The instance is **cached** and **shared** across the app.
///
/// Additionally, the `dispose` method attempts to automatically
/// clean up common Flutter types such as:
/// - [Sink] → calls `close()`
/// - [ChangeNotifier] → calls `dispose()`
/// - [StreamController] → calls `close()`
final class LazySingletonBind<T> implements IBind<T> {
  T? _instance;
  final T Function(IInjector i) _builder;

  /// Creates a [LazySingletonBind] using the provided factory function.
  LazySingletonBind(this._builder);

  /// Returns the cached instance of [T] if available,
  /// otherwise builds and caches it.
  @override
  T get(IInjector i) => _instance ??= _builder(i);

  /// Disposes of the cached instance, if present.
  ///
  /// If the instance implements [Sink], [ChangeNotifier], [StreamController],
  /// or has a `dispose()` method, the appropriate dispose or close method is called.
  ///
  /// Logs any disposal error when [Modugo.debugLogDiagnostics] is enabled.
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
