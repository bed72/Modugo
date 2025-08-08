// coverage:ignore-file

import 'package:modugo/src/routes/child_route.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';

/// Extension for [ChildRoute] to support injecting parent guards.
///
/// This extension allows creating a new [ChildRoute] instance that
/// prepends the provided [parentGuards] to the existing guards of this route.
/// This is useful when propagating guards from a parent module or route
/// to its children, ensuring consistent access control.
///
/// Example:
/// ```dart
/// final guardedRoute = childRoute.withInjectedGuards([authGuard]);
/// ```
extension ChildRouteExtensions on ChildRoute {
  /// Returns a new [ChildRoute] with [parentGuards] prepended to the existing guards.
  ///
  /// - [parentGuards]: The list of guards inherited from the parent route or module.
  ///
  /// Returns a copy of this route with the combined guards list.
  ChildRoute withInjectedGuards(List<IGuard> parentGuards) => ChildRoute(
    path: path,
    name: name,
    child: child,
    onExit: onExit,
    redirect: redirect,
    transition: transition,
    pageBuilder: pageBuilder,
    routePattern: routePattern,
    guards: [...parentGuards, ...guards],
    parentNavigatorKey: parentNavigatorKey,
  );
}
