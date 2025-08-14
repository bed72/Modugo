import 'dart:async';
import 'package:event_bus/event_bus.dart';

import 'package:modugo/src/module.dart';

import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/events/event_channel.dart';

/// Base module class for event-driven modules using [EventBus].
///
/// This class provides a convenient structure to:
/// - Register typed event listeners.
/// - Automatically dispose listeners when the module is destroyed.
/// - Use a custom [EventBus] or the default global one.
///
/// Extend this class to create modules that respond to specific events.
abstract class EventModule extends Module {
  /// Internal EventBus used by this module.
  ///
  /// Defaults to the global [defaultEvents] bus if no custom bus is provided.
  final EventBus _internalEventBus;

  /// Creates an instance of [EventModule].
  ///
  /// [eventBus] can be provided to use a custom event bus. If not provided,
  /// the default global [EventBus] will be used.
  EventModule({EventBus? eventBus})
    : _internalEventBus = eventBus ?? defaultEvents;

  /// Subclasses must implement this method to register all event listeners.
  ///
  /// Called automatically when the module is initialized via [initState].
  void listen();

  /// Registers a listener for events of type [T].
  ///
  /// The listener is automatically managed by the module. If [autoDispose] is `true`,
  /// a subscription is tracked and will be cancelled when [dispose] is called.
  ///
  /// Parameters:
  /// - [callback]: Function to execute when the event of type [T] is emitted.
  /// - [autoDispose]: If `true`, automatically disposes the listener when the module is destroyed.
  ///
  /// Example:
  /// ```dart
  /// on<UserLoggedInEvent>((event) {
  ///   print('User logged in: ${event.userId}');
  /// }, autoDispose: true);
  /// ```
  void on<T>(void Function(T event) callback, {bool? autoDispose}) {
    EventChannel.instance.on<T>(callback, eventBus: _internalEventBus);
    if (autoDispose ?? false) {
      // Track subscription to cancel later
      _moduleSubscriptions.add(_internalEventBus.on<T>().listen((_) {}));
    }
  }

  /// Tracks all subscriptions registered by this module that require disposal.
  ///
  /// Used internally to cancel subscriptions when [dispose] is called.
  final List<StreamSubscription> _moduleSubscriptions = [];

  @override
  void initState() {
    // Automatically register listeners when the module initializes
    listen();
    super.initState();
  }

  @override
  void dispose() {
    // Cancel all tracked subscriptions
    for (final sub in _moduleSubscriptions) {
      sub.cancel();
    }
    _moduleSubscriptions.clear();

    // Dispose all module-specific listeners from the EventChannel
    EventChannel.instance.disposeAll(eventBus: _internalEventBus);

    super.dispose();
  }
}
