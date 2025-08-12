import 'package:modugo/src/guard.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/models/guard_model.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

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

/// Extension for [ModuleRoute] to support injecting parent guards recursively.
///
/// This extension creates a new [ModuleRoute] with an internal wrapped module
/// that applies the [parentGuards] plus the module's own guards recursively
/// to all nested routes within the module. This ensures that guards set at the
/// parent module level affect all child routes within the nested module.
///
/// Example:
/// ```dart
/// final guardedModuleRoute = moduleRoute.withInjectedGuards([authGuard]);
/// ```
extension ModuleRouteExtensions on ModuleRoute {
  /// Returns a new [ModuleRoute] with guards injected recursively into its nested module.
  ///
  /// - [parentGuards]: The list of guards inherited from the parent route or module.
  ///
  /// Returns a copy of this route where the nested [module] is wrapped
  /// to propagate guards to all nested routes.
  ModuleRoute withInjectedGuards(List<IGuard> parentGuards) => ModuleRoute(
    path: path,
    name: name,
    redirect: redirect,
    routePattern: routePattern,
    parentNavigatorKey: parentNavigatorKey,
    module: GuardModel(module: module, guards: parentGuards),
  );
}

/// Extension for [ShellModuleRoute] to support injecting parent guards recursively.
///
/// This extension creates a new [ShellModuleRoute] where the parent guards are
/// injected into all child routes recursively. It keeps all other properties
/// unchanged.
///
/// Example:
/// ```dart
/// final guardedShellRoute = shellRoute.withInjectedGuards([authGuard]);
/// ```
extension ShellModuleRouteExtensions on ShellModuleRoute {
  /// Returns a new [ShellModuleRoute] with parent guards injected recursively into all nested routes.
  ///
  /// - [parentGuards]: The list of guards inherited from the parent route or module.
  ///
  /// Returns a copy of this route where all nested routes have the guards injected.
  ShellModuleRoute withInjectedGuards(List<IGuard> parentGuards) =>
      ShellModuleRoute(
        binds: binds,
        builder: builder,
        redirect: redirect,
        observers: observers,
        pageBuilder: pageBuilder,
        navigatorKey: navigatorKey,
        parentNavigatorKey: parentNavigatorKey,
        restorationScopeId: restorationScopeId,
        routes: propagateGuards(routes: routes, guards: parentGuards),
      );
}

/// Extension for [StatefulShellModuleRoute] to support injecting parent guards recursively.
///
/// This extension creates a new [StatefulShellModuleRoute] where the given [parentGuards]
/// are injected into all nested routes recursively. All other route properties remain unchanged.
///
/// Example:
/// ```dart
/// final guardedStatefulShellRoute = statefulShellRoute.withInjectedGuards([authGuard]);
/// ```
///
/// The resulting route will propagate the specified guards to all its child routes,
/// ensuring consistent access control across the entire shell structure.
extension StatefulShellModuleRouteExtensions on StatefulShellModuleRoute {
  /// Returns a new [StatefulShellModuleRoute] with [parentGuards] injected recursively into all nested routes.
  ///
  /// - [parentGuards]: The list of guards inherited from the parent route or module.
  ///
  /// This ensures that all child routes of the stateful shell route apply both the inherited
  /// guards and any guards they already have.
  StatefulShellModuleRoute withInjectedGuards(List<IGuard> parentGuards) =>
      StatefulShellModuleRoute(
        builder: builder,
        routePattern: routePattern,
        parentNavigatorKey: parentNavigatorKey,
        restorationScopeId: restorationScopeId,
        routes: propagateGuards(routes: routes, guards: parentGuards),
      );
}
