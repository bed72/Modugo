import 'dart:async';

import 'package:flutter/material.dart';

import 'package:modugo/src/logger.dart';

import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

/// Internal class representing a singleton binding in the [Injector].
///
/// This binding creates and stores a **single instance** of a dependency
/// as soon as it is first requested, and keeps it in memory until disposal.
///
/// The builder can be asynchronous, allowing initialization
/// that requires awaiting (e.g., async setup, I/O operations).
///
/// The created instance is cached and returned on subsequent calls.
///
/// Example usage:
/// ```dart
/// injector.addSingleton<MyService>((injector) async {
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
final class SingletonBind<T> implements IBind<T> {
  /// Cached future of the singleton instance to handle async initialization.
  Future<T>? _instanceFuture;

  /// Resolved instance after the future completes.
  T? _resolvedInstance;

  /// The builder function that creates the instance.
  /// Can return [T] or [Future<T>].
  final FutureOr<T> Function(IInjector i) _builder;

  /// Creates a [SingletonBind] with the given asynchronous builder.
  SingletonBind(this._builder);

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
