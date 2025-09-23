// coverage:ignore-file

import 'dart:async';
import 'package:event_bus/event_bus.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/events/event_channel.dart';

/// Mixin that provides automatic event listening for [Module]s.
///
/// This mixin allows:
/// - Automatic invocation of [listen()] when the module is initialized.
/// - Typed event listener registration.
/// - Automatic disposal of subscriptions when the module is disposed.
/// - Use of a custom [EventBus] or the global [defaultEvents].
///
/// Usage:
/// ```dart
/// final class MyModule extends Module with EventModuleMixin {
///   @override
///   void listen() {
///     on<UserLoggedInEvent>((event) {
///       print('User logged in: ${event.userId}');
///     }, autoDispose: true);
///   }
/// }
/// ```
mixin EventRegistry on Module {
  late final EventBus _internalEventBus = defaultEvents;

  /// Tracks all subscriptions registered by this module that require disposal.
  ///
  /// Used internally to cancel subscriptions when [dispose] is called.
  final List<StreamSubscription> _moduleSubscriptions = [];

  /// Called automatically when [initState] is executed.
  ///
  /// Initializes the internal EventBus and calls [listen].
  @override
  void initState() {
    listen();
    super.initState();
  }

  /// Register typed event listeners here.
  ///
  /// This method is called automatically when the module initializes.
  void listen();

  /// Registers a listener for events of type [T].
  ///
  /// If [autoDispose] is `true`, the subscription is automatically
  /// cancelled when [dispose] is called.
  void on<T>(void Function(T event) callback, {bool autoDispose = false}) {
    EventChannel.i.on<T>(callback, eventBus: _internalEventBus);

    if (autoDispose) {
      _moduleSubscriptions.add(_internalEventBus.on<T>().listen((_) {}));
    }
  }

  /// Cancels all tracked subscriptions and clears event listeners.
  @override
  void dispose() {
    for (final sub in _moduleSubscriptions) {
      sub.cancel();
    }
    _moduleSubscriptions.clear();

    EventChannel.i.disposeAll(eventBus: _internalEventBus);

    super.dispose();
  }
}
