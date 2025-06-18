import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

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
/// Example:
/// ```dart
/// ShellModuleRoute(
///   routes: [
///     ModuleRoute('/home', module: HomeModule()),
///     ModuleRoute('/profile', module: ProfileModule()),
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

  /// Optional navigator observers for tracking navigation events.
  final List<NavigatorObserver>? observers;

  /// Optional binds injected when this shell is active.
  ///
  /// These binds are scoped to the shell and disposed when it’s no longer in use.
  final List<void Function(IInjector)> binds;

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
    this.binds = const [],
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellModuleRoute &&
          runtimeType == other.runtimeType &&
          listEquals(routes, other.routes) &&
          listEquals(observers, other.observers) &&
          navigatorKey == other.navigatorKey &&
          restorationScopeId == other.restorationScopeId &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      Object.hashAll(observers ?? []) ^
      navigatorKey.hashCode ^
      restorationScopeId.hashCode ^
      parentNavigatorKey.hashCode;
}
