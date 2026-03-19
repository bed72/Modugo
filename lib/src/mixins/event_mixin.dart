// coverage:ignore-file

import 'dart:async';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/events/event.dart';

/// Mixin that provides event listening capabilities for [Module]s.
///
/// This mixin allows:
/// - Automatic invocation of [listen()] when the module is configured
///   (via `_configureBinders` in [Module]).
/// - Typed event listener registration via [on].
/// - Manual cleanup of subscriptions via [dispose].
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

  /// Override this method to register your event listeners.
  ///
  /// Called automatically by the framework during module configuration
  /// (after `binds()` have been registered).
  void listen();

  /// Registers a listener for events of type [T].
  ///
  /// If [autoDispose] is `true` (default), the listener is automatically
  /// cancelled when [dispose] is called on this module.
  void on<T>(void Function(T event) callback, {bool autoDispose = true}) {
    final sub = Event.i.streamOf<T>().listen(callback);
    if (autoDispose) _subscriptions.add(sub);
  }

  /// Cancels all tracked subscriptions and clears the list.
  ///
  /// This method is NOT called automatically by the framework.
  /// It is the consumer's responsibility to call [dispose] when
  /// the module's event listeners are no longer needed.
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
