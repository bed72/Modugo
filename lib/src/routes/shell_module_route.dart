import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/models/route_pattern_model.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

/// A modular shell route that wraps a group of child [IModule] routes within a common layout or container.
///
/// This is useful for building structures like tab navigation, sidebars,
/// or persistent UI scaffolds where multiple routes share a layout.
///
/// The shell provides:
/// - a shared [navigatorKey] for nested navigation
/// - optional [observers], [restorationScopeId], and [parentNavigatorKey]
/// - a [builder] or [pageBuilder] to render a common UI container
/// - optional [binds] for temporary dependency injection scoped to the shell
///
/// Optionally supports [routePattern] to enable custom regex-based
/// matching and parameter extraction independent of GoRouter.
///
/// Example:
/// ```dart
/// ShellModuleRoute(
///   routes: [
///     ModuleRoute(path: '/home', module: HomeModule()),
///     ModuleRoute(path: '/profile', module: ProfileModule()),
///   ],
///   builder: (context, state, child) {
///     return AppScaffold(child: child);
///   },
/// );
/// ```
@immutable
final class ShellModuleRoute implements IModule {
  /// The list of child modules to be rendered inside the shell.
  final List<IModule> routes;

  /// Optional ID used for state restoration (Flutter feature).
  final String? restorationScopeId;

  /// Optional route matching pattern using regex and parameter names.
  ///
  /// This allows the module to be matched via a regular expression
  /// independently of GoRouter's matching logic.
  final RoutePatternModel? routePattern;

  /// Optional navigator observers for tracking navigation events.
  final List<NavigatorObserver>? observers;

  /// Optional binds injected when this shell is active.
  ///
  /// These binds are scoped to the shell and disposed when it’s no longer in use.
  final List<void Function(GetIt)> binds;

  /// Navigator key used to isolate navigation inside the shell.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The navigator key of the parent (for nested navigator hierarchy).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

  /// Optional redirect logic that runs before the shell is entered.
  ///
  /// Return `null` to allow access; return a path string to redirect.
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  /// Function that wraps the [child] widget with a shell UI (e.g. layout, scaffold).
  ///
  /// This is called whenever a child route within the shell is rendered.
  final Widget Function(
    BuildContext context,
    GoRouterState state,
    Widget child,
  )?
  builder;

  /// Custom [Page] builder that wraps the shell UI into a [Page] object.
  ///
  /// Useful when you need to customize page transitions or use custom page types.
  final Page<dynamic> Function(
    BuildContext context,
    GoRouterState state,
    Widget child,
  )?
  pageBuilder;

  /// Creates a [ShellModuleRoute] that groups [routes] inside a shared shell layout.
  const ShellModuleRoute({
    required this.routes,
    required this.builder,
    this.redirect,
    this.observers,
    this.pageBuilder,
    this.navigatorKey,
    this.routePattern,
    this.binds = const [],
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellModuleRoute &&
          runtimeType == other.runtimeType &&
          routePattern == other.routePattern &&
          navigatorKey == other.navigatorKey &&
          listEquals(routes, other.routes) &&
          listEquals(observers, other.observers) &&
          restorationScopeId == other.restorationScopeId &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      Object.hashAll(observers ?? []) ^
      navigatorKey.hashCode ^
      routePattern.hashCode ^
      restorationScopeId.hashCode ^
      parentNavigatorKey.hashCode;
}
