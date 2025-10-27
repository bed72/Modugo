// coverage:ignore-file

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Provides a declarative, fluent, and strongly-typed API
/// for building route structures inside a [Module].
///
/// This mixin defines a set of helper methods — [child], [module],
/// [alias], [shell], and [statefulShell] — that simplify the creation of
/// routes in the Modugo ecosystem, removing the need to manually
/// instantiate route classes like [ChildRoute] or [ModuleRoute].
///
/// ### Benefits:
/// - Cleaner, declarative syntax inside `routes()`
/// - Reduced boilerplate and improved readability
/// - Strong typing with IDE autocomplete
/// - Consistent route construction across all modules
///
/// ### Example:
/// ```dart
/// final class AppModule extends Module with IHelper {
///   @override
///   List<IRoute> routes() => [
///     route('/', child: (_, _) => const HomePage()),
///     module('/auth', AuthModule()),
///     alias(from: '/cart/:id', to: '/order/:id'),
///     shell(
///       builder: (_, _, child) => AppShell(child: child),
///       routes: [
///         route('/settings', child: (_, _) => const SettingsPage()),
///       ],
///     ),
///     statefulShell(
///       builder: (_, _, shell) => BottomBarWidget(shell: shell),
///       routes: [
///         module('/feed', FeedModule()),
///         module('/profile', ProfileModule()),
///       ],
///     ),
///   ];
/// }
/// ```
///
/// ### Notes:
/// - All helpers return their respective [IRoute] subtype.
/// - This mixin is stateless and can safely be combined with
///   [IBinder] and [IRouter] in any [Module].
mixin IHelper {
  /// Creates an [AliasRoute] to define an alternate path that maps
  /// to an existing [ChildRoute]. Useful for SEO-friendly URLs,
  /// backward compatibility, or multiple access points for the same screen.
  ///
  /// Example:
  /// ```dart
  /// alias(from: '/cart/:id', to: '/order/:id');
  /// ```
  AliasRoute alias({required String from, required String to}) =>
      AliasRoute(from: from, to: to);

  /// Creates a [ChildRoute] for a simple page or screen within a [Module].
  ///
  /// This is the most common route type, used for mapping a single
  /// path to a widget.
  ///
  /// Example:
  /// ```dart
  /// route('/home', child: (_, _) => const HomePage());
  /// ```
  ChildRoute child({
    required Widget Function(BuildContext, GoRouterState) child,
    String? name,
    String? path,
    TypeTransition? transition,
    List<IGuard> guards = const [],
    GlobalKey<NavigatorState>? parentNavigatorKey,
    Page<dynamic> Function(BuildContext, GoRouterState)? pageBuilder,
    FutureOr<bool> Function(BuildContext context, GoRouterState state)? onExit,
  }) => ChildRoute(
    name: name,
    child: child,
    guards: guards,
    onExit: onExit,
    path: path ?? '/',
    transition: transition,
    pageBuilder: pageBuilder,
    parentNavigatorKey: parentNavigatorKey,
  );

  /// Creates a [ModuleRoute] that links to another [Module].
  ///
  /// This allows composing multiple feature modules together
  /// in a hierarchical structure.
  ///
  /// Example:
  /// ```dart
  /// module('/auth', AuthModule());
  /// ```
  ModuleRoute module({
    required Module module,
    String? name,
    String? path,
    GlobalKey<NavigatorState>? parentNavigatorKey,
  }) => ModuleRoute(
    name: name,
    module: module,
    path: path ?? '/',
    parentNavigatorKey: parentNavigatorKey,
  );

  /// Creates a [ShellModuleRoute] that wraps a group of child routes
  /// under a common layout or scaffold.
  ///
  /// Ideal for structures like tab navigation or persistent UIs.
  ///
  /// Example:
  /// ```dart
  /// shell(
  ///   builder: (_, _, child) => AppScaffold(child: child),
  ///   routes: [
  ///     route('/tab1', child: (_, _) => const Tab1Page()),
  ///     route('/tab2', child: (_, _) => const Tab2Page()),
  ///   ],
  /// );
  /// ```
  ShellModuleRoute shell({
    required List<IRoute> routes,
    required Widget Function(BuildContext, GoRouterState, Widget) builder,
    List<NavigatorObserver>? observers,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    Page<dynamic> Function(BuildContext, GoRouterState, Widget)? pageBuilder,
  }) => ShellModuleRoute(
    routes: routes,
    builder: builder,
    observers: observers,
    pageBuilder: pageBuilder,
    navigatorKey: navigatorKey,
    parentNavigatorKey: parentNavigatorKey,
  );

  /// Creates a [StatefulShellModuleRoute] for complex navigations
  /// where each branch maintains its own navigation stack.
  ///
  /// Commonly used for bottom navigation or tab-based layouts
  /// that preserve state per branch.
  ///
  /// Example:
  /// ```dart
  /// statefulShell(
  ///   builder: (_, _, shell) => BottomBarWidget(shell: shell),
  ///   routes: [
  ///     module('/feed', FeedModule()),
  ///     module('/profile', ProfileModule()),
  ///   ],
  /// );
  /// ```
  StatefulShellModuleRoute statefulShell({
    required List<IRoute> routes,
    required Widget Function(
      BuildContext,
      GoRouterState,
      StatefulNavigationShell,
    )
    builder,
    GlobalKey<StatefulNavigationShellState>? key,
    GlobalKey<NavigatorState>? parentNavigatorKey,
  }) => StatefulShellModuleRoute(
    key: key,
    routes: routes,
    builder: builder,
    parentNavigatorKey: parentNavigatorKey,
  );
}
