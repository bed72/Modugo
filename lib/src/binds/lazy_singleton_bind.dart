import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';

import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

/// Represents a lazy singleton binding in the [Injector].
///
/// This binding creates a **single instance** of type [T],
/// but only when it's first requested (lazy instantiation).
///
/// The builder can be asynchronous, allowing initialization
/// that requires awaiting (e.g., async setup, I/O operations).
///
/// The created instance is cached and reused on subsequent calls.
///
/// Example usage:
/// ```dart
/// injector.addLazySingleton<MyService>((injector) async {
///   final service = MyService();
///   await service.init();
///   return service;
/// });
/// ```
///
/// The `get` method returns a [Future<T>] to always await the
/// creation or retrieval of the instance.
///
/// The `dispose` method attempts to clean up the instance if it
/// supports common Flutter/Dart disposal patterns:
/// - If the instance is a [Sink], calls `close()`
/// - If it's a [ChangeNotifier], calls `dispose()`
/// - If it's a [StreamController], calls `close()`
/// - Otherwise, tries to call a `dispose()` method if present.
///
/// Disposal errors are logged using [Logger].
final class LazySingletonBind<T> implements IBind<T> {
  /// Cached future of the instance, to handle async lazy initialization.
  Future<T>? _instanceFuture;

  /// The resolved instance after the future completes.
  T? _resolvedInstance;

  /// The builder function that creates the instance.
  /// Can return [T] or [Future<T>].
  final FutureOr<T> Function(IInjector i) _builder;

  /// Creates a lazy singleton bind with the given asynchronous builder.
  LazySingletonBind(this._builder);

  /// Returns the singleton instance asynchronously.
  ///
  /// If the instance was not yet created, it invokes the builder,
  /// caches the [Future], and awaits its completion.
  /// Subsequent calls await the cached [Future].
  @override
  FutureOr<T> get(IInjector i) async {
    if (_instanceFuture == null) {
      final result = _builder(i);
      _instanceFuture = result is Future<T> ? result : Future.value(result);
      _resolvedInstance = await _instanceFuture!;
    }

    return _instanceFuture!;
  }

  /// Disposes the singleton instance if it exists.
  ///
  /// Calls appropriate disposal methods based on the instance type:
  /// - [Sink.close()]
  /// - [ChangeNotifier.dispose()]
  /// - [StreamController.close()]
  /// - Calls `dispose()` if present on the instance.
  ///
  /// Clears the cached instance and future.
  /// Logs any disposal errors.
  @override
  void dispose() async {
    final instance = _resolvedInstance;
    if (instance == null) return;

    try {
      if (instance is Sink) {
        instance.close();
      } else if (instance is ChangeNotifier) {
        instance.dispose();
      } else if (instance is StreamController) {
        instance.close();
      } else {
        _tryCallDispose(instance);
      }
      _instanceFuture = null;
      _resolvedInstance = null;
    } catch (exception, stack) {
      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $exception',
      );
      Logger.error('$stack');
    }
  }

  /// Attempts to invoke a `dispose()` method on the instance if it exists.
  ///
  /// Silently ignores errors if the method is not present or fails.
  void _tryCallDispose(dynamic instance) {
    try {
      final disposeMethod = instance.dispose;
      if (disposeMethod != null && disposeMethod is Function) {
        disposeMethod();
      }
    } catch (exception) {
      Logger.injection(
        'Error disposing instance of type ${instance.runtimeType}: $exception',
      );
    }
  }
}
