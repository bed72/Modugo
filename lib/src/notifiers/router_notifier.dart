import 'package:flutter/foundation.dart';

/// A global route notifier that emits the current route location.
///
/// This is used internally by Modugo as the default [refreshListenable]
/// for GoRouter, and can also be listened to manually.
///
/// Example:
/// ```dart
/// Modugo.routeNotifier.addListener(() {
///   final location = Modugo.routeNotifier.value;
///   if (location == '/home') {
///     refreshHomeCarousel();
///   }
/// });
/// ```
final class RouteNotifier extends ValueNotifier<String> {
  /// Initializes with the default route `/`.
  RouteNotifier() : super('/');

  /// Updates the notifier with the new [location].
  ///
  /// Notifies listeners only if the [location] is different from the current value.
  set update(String location) {
    if (location != value) value = location;
  }
}
