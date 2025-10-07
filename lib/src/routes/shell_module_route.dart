import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

/// A modular shell route that wraps a group of child [IRoute] routes within a common layout or container.
///
/// This is useful for building structures like tab navigation, sidebars,
/// or persistent UI scaffolds where multiple routes share a layout.
///
/// The shell provides:
/// - a shared [navigatorKey] for nested navigation
/// - optional [observers] and [parentNavigatorKey]
/// - a [builder] or [pageBuilder] to render a common UI container
///
/// Example:
/// ```dart
/// ShellModuleRoute(
///   routes: [
///     module(path: '/home', module: HomeModule()),
///     module(path: '/profile', module: ProfileModule()),
///   ],
///   builder: (context, state, child) {
///     return AppScaffold(child: child);
///   },
/// );
/// ```
@immutable
final class ShellModuleRoute implements IRoute {
  /// The list of child modules to be rendered inside the shell.
  final List<IRoute> routes;

  /// Optional navigator observers for tracking navigation events.
  final List<NavigatorObserver>? observers;

  /// Navigator key used to isolate navigation inside the shell.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The navigator key of the parent (for nested navigator hierarchy).
  final GlobalKey<NavigatorState>? parentNavigatorKey;

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
    this.observers,
    this.pageBuilder,
    this.navigatorKey,
    this.parentNavigatorKey,
  });

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      Object.hashAll(observers ?? []) ^
      navigatorKey.hashCode ^
      parentNavigatorKey.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellModuleRoute &&
          runtimeType == other.runtimeType &&
          navigatorKey == other.navigatorKey &&
          listEquals(routes, other.routes) &&
          listEquals(observers, other.observers) &&
          parentNavigatorKey == other.parentNavigatorKey;
}
