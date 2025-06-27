/// Represents a change in route navigation, including the previous and current locations
/// and the type of navigation that triggered the change.
///
/// Used by [RouteNotifier] to broadcast route transitions.
final class RouteChangeEvent {
  /// The previous route location.
  final String? previous;

  /// The current route location.
  final String? current;

  /// Creates a new [RouteChangeEvent].
  const RouteChangeEvent({required this.current, required this.previous});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteChangeEvent &&
          current == other.current &&
          previous == other.previous &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => Object.hash(previous, current);

  @override
  String toString() =>
      'RouteChangeEvent(previous: $previous, current: $current)';
}
