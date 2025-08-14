import 'package:event_bus/event_bus.dart';

import 'package:modugo/src/events/event.dart';

/// Singleton class to manage modular events across the application.
///
/// Provides a centralized way to:
/// - Register listeners for typed events.
/// - Fire events globally or via a custom EventBus.
/// - Automatically manage subscriptions with broadcast support.
/// - Dispose specific listeners or all listeners from an EventBus.
///
/// This class is similar in purpose to `ModularEvent`, but provides
/// a more lightweight, decoupled approach for event-driven modules.
final class EventChannel {
  static EventChannel? _instance;

  EventChannel._();

  /// Singleton instance of [EventChannel].
  ///
  /// Ensures only one instance exists throughout the application.
  static EventChannel get instance => _instance ??= EventChannel._();

  /// Registers a listener for events of type [T].
  ///
  /// Automatically handles broadcast streams and provides type-safe event handling.
  ///
  /// Parameters:
  /// - [callback]: Function to execute when an event of type [T] is emitted.
  /// - [eventBus]: Optional custom EventBus instance. Defaults to [defaultEvents].
  /// - [broadcast]: If `true`, converts the stream to a broadcast stream.
  ///
  /// Example:
  /// ```dart
  /// EventChannel.instance.on<UserLoggedInEvent>((event) {
  ///   print('User logged in: ${event.userId}');
  /// });
  /// ```
  void on<T>(
    void Function(T event) callback, {
    EventBus? eventBus,
    bool broadcast = true,
  }) {
    eventBus ??= defaultEvents;
    final busId = eventBus.hashCode;

    eventSubscriptions[busId] ??= {};
    eventSubscriptions[busId]?[T]?.cancel();

    final stream =
        broadcast ? eventBus.on<T>().asBroadcastStream() : eventBus.on<T>();
    eventSubscriptions[busId]![T] = stream.listen((event) {
      callback(event);
    });
  }

  /// Emits (fires) an event globally.
  ///
  /// All listeners registered for this event type [T] will be notified.
  ///
  /// Parameters:
  /// - [event]: The event instance to emit.
  /// - [eventBus]: Optional custom EventBus. Defaults to [defaultEvents].
  ///
  /// Example:
  /// ```dart
  /// EventChannel.emit(UserLoggedInEvent(userId: '42'));
  /// ```
  static void emit<T>(T event, {EventBus? eventBus}) {
    eventBus ??= defaultEvents;
    eventBus.fire(event);
  }

  /// Disposes a specific listener for an event type [T].
  ///
  /// Cancels the active subscription for the given type and removes it from
  /// the internal tracking map.
  ///
  /// Parameters:
  /// - [eventBus]: Optional custom EventBus. Defaults to [defaultEvents].
  ///
  /// Example:
  /// ```dart
  /// EventChannel.instance.dispose<UserLoggedInEvent>();
  /// ```
  void dispose<T>({EventBus? eventBus}) {
    eventBus ??= defaultEvents;
    final busId = eventBus.hashCode;
    eventSubscriptions[busId]?[T]?.cancel();
    eventSubscriptions[busId]?.remove(T);
  }

  /// Disposes all listeners registered on a given EventBus.
  ///
  /// Useful for cleaning up all subscriptions when a module or component
  /// is being destroyed.
  ///
  /// Parameters:
  /// - [eventBus]: Optional custom EventBus. Defaults to [defaultEvents].
  ///
  /// Example:
  /// ```dart
  /// EventChannel.instance.disposeAll();
  /// ```
  void disposeAll({EventBus? eventBus}) {
    eventBus ??= defaultEvents;
    final busId = eventBus.hashCode;
    eventSubscriptions[busId]?.values.forEach((sub) => sub.cancel());
    eventSubscriptions[busId]?.clear();
  }
}
