import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/injector.dart';
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
  final T Function(Injector i) _builder;

  /// Creates a [LazySingletonBind] using the provided factory function.
  LazySingletonBind(this._builder);

  /// Returns the cached instance of [T] if available,
  /// otherwise builds and caches it.
  @override
  T get(Injector i) => _instance ??= _builder(i);

  /// Disposes of the cached instance, if present.
  ///
  /// If the instance implements [Sink], [ChangeNotifier], or [StreamController],
  /// the appropriate dispose or close method is called.
  ///
  /// Logs any disposal error when [Modugo.debugLogDiagnostics] is enabled.
  @override
  void dispose() {
    final instance = _instance;
    try {
      if (instance is Sink) instance.close();
      if (instance is ChangeNotifier) instance.dispose();
      if (instance is StreamController) instance.close();
      _instance = null;
    } catch (e, stack) {
      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $e',
      );
      Logger.error('$stack');
    }
  }
}
