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

  /// Registers a listener for events of type [T] and returns the [StreamSubscription].
  ///
  /// If [autoDispose] is `true` (default), the subscription is tracked and
  /// automatically cancelled when [dispose] is called on this module.
  ///
  /// If [autoDispose] is `false`, the subscription is **not** tracked by this
  /// module — the returned [StreamSubscription] is the caller's responsibility
  /// to cancel when no longer needed.
  ///
  /// ```dart
  /// // Managed automatically:
  /// on<UserEvent>((e) => handleUser(e));
  ///
  /// // Manual management:
  /// final sub = on<SystemEvent>((e) => handleSystem(e), autoDispose: false);
  /// // later:
  /// sub.cancel();
  /// ```
  StreamSubscription<T> on<T>(
    void Function(T event) callback, {
    bool autoDispose = true,
  }) {
    final sub = Event.i.streamOf<T>().listen(callback);
    if (autoDispose) _subscriptions.add(sub);
    return sub;
  }

  /// Cancels all tracked subscriptions and clears the list.
  ///
  /// **Cleanup order matters:** always call [dispose] **before** any
  /// `GetIt.reset()`, `GetIt.unregister()`, or `GetIt.popScope()` that
  /// removes services accessed by active listeners. Reversing this order
  /// may cause `ServiceNotFoundException` in still-active callbacks.
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
