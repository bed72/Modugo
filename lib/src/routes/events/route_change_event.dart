import 'package:modugo/src/routes/events/route_action_event.dart';

/// Represents a change in route navigation, including the previous and current locations
/// and the type of navigation that triggered the change.
///
/// Used by [RouteNotifier] to broadcast route transitions.
final class RouteChangeEvent {
  /// The previous route location.
  final String? previous;

  /// The current route location.
  final String? current;

  /// The type of navigation action that triggered the change.
  final RouteActionEvent action;

  /// Creates a new [RouteChangeEvent].
  const RouteChangeEvent({
    required this.action,
    required this.current,
    required this.previous,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteChangeEvent &&
          action == other.action &&
          current == other.current &&
          previous == other.previous &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => Object.hash(previous, current, action);

  @override
  String toString() =>
      'RouteChangeEvent(previous: $previous, current: $current, action: $action)';
}
