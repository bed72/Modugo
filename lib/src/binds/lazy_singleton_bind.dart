import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';

import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

/// Internal class representing a lazy singleton binding in the [Injector].
///
/// This binding creates a **single instance** of a dependency,
/// but **only when it's first requested** (lazy instantiation).
///
/// Use cases:
/// - Optimize performance and memory by delaying creation until needed.
/// - Share a single instance across the app.
///
/// Example usage within the [Injector]:
/// ```dart
/// injector.addLazySingleton((i) => AuthService());
/// ```
///
/// The `AuthService` will only be instantiated upon the first call to
/// `Modugo.get<AuthService>()`.
///
/// The created instance is cached and returned on subsequent calls.
///
/// Additionally, the `dispose` method attempts to clean up common Flutter types:
/// - If the instance is a [Sink], calls `close()`
/// - If it's a [ChangeNotifier], calls `dispose()`
/// - If it's a [StreamController], calls `close()`
///
/// Disposal errors are logged when [Modugo.debugLogDiagnostics] is enabled.
final class LazySingletonBind<T> implements IBind<T> {
  T? _instance;
  final T Function(IInjector i) _builder;

  /// Creates a [LazySingletonBind] with the provided factory function.
  LazySingletonBind(this._builder);

  /// Returns the cached instance of [T] if it exists,
  /// otherwise builds it via [_builder] and caches it.
  @override
  T get(IInjector i) => _instance ??= _builder(i);

  /// Disposes of the cached instance, if present.
  ///
  /// If the instance implements [Sink], [ChangeNotifier], [StreamController],
  /// or has a `dispose()` method, the appropriate dispose or close method is called.
  ///
  /// Logs any disposal error when [Modugo.debugLogDiagnostics] is enabled.
  /// Disposes the cached instance if present,
  /// calling the appropriate cleanup method if applicable.
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
    } catch (exception, stack) {
      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $exception',
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
    } catch (exception) {
      // If dispose method doesn't exist or fails, ignore silently
      // This allows objects without dispose method to be cleaned up normally

      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $exception',
      );
    }
  }
}
