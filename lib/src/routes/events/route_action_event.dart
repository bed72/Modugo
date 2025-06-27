// coverage:ignore-file

/// Defines the type of navigation action that occurred.
///
/// Used in [RouteChangeEvent] to describe how the user arrived at a new route.
enum RouteActionEvent {
  /// Indicates the route was popped using [Navigator.pop].
  pop,

  /// Indicates the route was pushed via [GoRouter.go] or [GoRouter.push].
  push,

  /// Indicates the route was replaced via [GoRouter.replace] or similar.
  replace,

  /// Indicates the route changed due to a redirect (e.g. guards or manual redirect).
  redirect,
}
