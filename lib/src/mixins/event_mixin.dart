// coverage:ignore-file

import 'dart:async';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/events/event.dart';

/// Mixin that provides automatic event listening for [Module]s.
///
/// This mixin allows:
/// - Automatic invocation of [listen()] when the module initializes.
/// - Typed event listener registration via [on].
/// - Automatic cleanup of subscriptions when the module is disposed.
///
/// Example:
/// ```dart
/// final class MyModule extends Module with IEvent {
///   @override
///   void listen() {
///     on<UserLoggedInEvent>((event) {
///       print('User logged in: ${event.userId}');
///     });
///   }
/// }
/// ```
mixin IEvent on Module {
  /// Tracks all subscriptions registered by this module.
  ///
  /// Each subscription is automatically cancelled when [dispose] is called.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Called automatically when the module initializes.
  ///
  /// Registers listeners via [listen].
  @override
  void initState() {
    super.initState();
    listen();
  }

  /// Override this method to register your event listeners.
  ///
  /// Called once during module initialization.
  void listen();

  /// Registers a listener for events of type [T].
  ///
  /// If [autoDispose] is `true` (default), the listener is automatically
  /// cancelled when the module is disposed.
  void on<T>(void Function(T event) callback, {bool autoDispose = true}) {
    final sub = Event.i.streamOf<T>().listen(callback);
    if (autoDispose) _subscriptions.add(sub);
  }

  /// Cancels all tracked subscriptions and clears listeners.
  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
