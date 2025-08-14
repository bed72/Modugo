// coverage:ignore-file

import 'package:flutter/foundation.dart';

/// Event fired whenever the application's current route changes.
///
/// This event is intended to be used with [EventChannel] or any event-driven
/// system to notify listeners that the active route has changed.
///
/// Example usage:
/// ```dart
/// EventChannel.instance.on<RouteChangedEventModel>((event) {
///   print('Route changed to: ${event.location}');
/// });
/// ```
///
/// Emitting the event:
/// ```dart
/// EventChannel.emit(RouteChangedEventModel('/home'));
/// ```
@immutable
final class RouteChangedEventModel {
  /// The full path of the current route.
  final String value;

  /// Creates a new [RouteChangedEventModel] with the given [value].
  const RouteChangedEventModel(this.value);

  /// Overrides equality operator to compare events by [value].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteChangedEventModel && other.value == value;
  }

  /// Provides a hash code based on [value] to ensure consistent behavior in maps and sets.
  @override
  int get hashCode => value.hashCode;

  /// Returns a readable string representation for debugging purposes.
  @override
  String toString() => 'RouteChangedEventModel(location: $value)';
}
