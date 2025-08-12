import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';

import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

/// Internal class representing a singleton binding in the [Injector].
///
/// This binding creates and stores a **single instance** of a dependency
/// as soon as it is first requested, and keeps it in memory until disposal.
///
/// Unlike [LazySingletonBind], this does not intentionally delay instantiation;
/// the instance is created on the first access and cached.
///
/// Typical usage within the [Injector]:
/// ```dart
/// injector.addSingleton((i) => AppConfig());
/// ```
///
/// The instance will be created on the first call to `Bind.get<AppConfig>()`
/// and shared thereafter.
///
/// The `dispose` method attempts to clean up common Flutter types:
/// - If the instance is a [Sink], calls `close()`
/// - If it's a [ChangeNotifier], calls `dispose()`
/// - If it's a [StreamController], calls `close()`
///
/// Any disposal errors are logged when [Modugo.debugLogDiagnostics] is enabled.
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
    } catch (exception) {
      // If dispose method doesn't exist or fails, ignore silently
      // This allows objects without dispose method to be cleaned up normally

      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $exception',
      );
    }
  }
}
