import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

/// A route guard for access control in Modugo.
///
/// Implement this interface to create custom route guards.
/// Guards are evaluated before route activation and may redirect
/// to another path if access is denied.
///
/// ### Example:
/// ```dart
/// class AuthGuard implements IGuard {
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
///     final authService = Modugo.get<AuthService>();
///     return authService.isLoggedIn ? null : '/login';
///   }
/// }
/// ```
abstract class IGuard {
  /// Called before a route is activated.
  ///
  /// Returns `null` if access is allowed, or a string path to redirect
  /// to another location (e.g., `/login`) if access is denied.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}
