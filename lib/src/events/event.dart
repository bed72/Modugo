import 'dart:async';

/// Global default event channel instance.
///
/// Provides decoupled communication between modules and components
/// without relying on external dependencies.
final Event events = Event._();

/// Singleton class that manages event-based communication using [StreamController].
///
/// This implementation replaces the `event_bus` package, leveraging
/// Dart's native [Stream] API to provide a lightweight, type-safe event system.
final class Event {
  static Event? _instance;
  final Map<Type, StreamController<dynamic>> _controllers = {};
  final Map<Type, StreamSubscription<dynamic>> _subscriptions = {};

  Event._();

  /// Returns the singleton instance of [Event].
  static Event get i => _instance ??= Event._();

  /// Returns a broadcast [Stream] for events of type [T].
  ///
  /// This allows external listeners (like [IEvent]) to subscribe to event streams
  /// without directly accessing internal controllers.
  Stream<T> streamOf<T>() => _getOrCreateController<T>().stream;

  /// Registers a listener for events of type [T].
  ///
  /// Example:
  /// ```dart
  /// EventChannel.i.on<UserLoggedInEvent>((event) {
  ///   print('User logged in: ${event.userId}');
  /// });
  /// ```
  void on<T>(void Function(T event) callback, {bool broadcast = true}) {
    final controller = _getOrCreateController<T>(broadcast: broadcast);

    _subscriptions[T]?.cancel();
    _subscriptions[T] = controller.stream.listen((event) => callback(event));
  }

  /// Emits (fires) an event of type [T].
  ///
  /// All listeners registered for this type will be notified.
  static void emit<T>(T event) {
    final controller = i._controllers[T];
    if (controller == null || controller.isClosed) return;
    controller.add(event);
  }

  /// Disposes a specific listener for event type [T].
  void dispose<T>() {
    _subscriptions[T]?.cancel();
    _subscriptions.remove(T);
  }

  /// Disposes all listeners and closes all stream controllers.
  void disposeAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Ensures a [StreamController] exists for the given event type [T].
  StreamController<T> _getOrCreateController<T>({bool broadcast = true}) {
    if (_controllers[T] case final existing?) {
      return existing as StreamController<T>;
    }

    final controller =
        broadcast ? StreamController<T>.broadcast() : StreamController<T>();

    _controllers[T] = controller;
    return controller;
  }
}
