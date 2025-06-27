import 'package:flutter/foundation.dart';

import 'package:modugo/src/routes/events/route_change_event.dart';

/// A global route notifier that emits [RouteChangeEvent] whenever a navigation change occurs.
///
/// This is used internally by Modugo as the default [refreshListenable]
/// for GoRouter, and can also be listened to manually.
///
/// It provides complete information about the route transition:
/// - `previous`: previous location
/// - `current`: current location
///
/// Example:
/// ```dart
/// Modugo.routeNotifier.addListener(() {
///   final event = Modugo.routeNotifier.value;
///   if (event.current == '/home') {
///     refreshHomeCarousel();
///   }
/// });
/// ```
final class RouteNotifier extends ValueNotifier<RouteChangeEvent> {
  /// Creates a [RouteNotifier] initialized with a default route event.
  ///
  /// Defaults to `/` for both previous and current routes.
  RouteNotifier() : super(const RouteChangeEvent(current: '/', previous: '/'));

  /// Updates the notifier with a new [RouteChangeEvent].
  ///
  /// Notifies listeners only if the [current] route differs from the last known one.
  void update(RouteChangeEvent event) {
    if (event != value) value = event;
  }
}
