import 'package:modugo/src/guard.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/redirect_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// Extension for [ChildRoute] to support injecting inherited guards.
///
/// These helpers do not mean that [ChildRoute] has its own `parentGuards`.
/// The parameter is only passed into the extension method so guards
/// defined at a parent level (e.g. Module, Shell) can be prepended here.
///
extension ChildRouteExtensions on ChildRoute {
  /// Returns a copy of this route with the given [inheritedGuards] prepended
  /// to the existing [guards] of the [ChildRoute].
  ChildRoute withInjectedGuards(List<IGuard> inheritedGuards) => ChildRoute(
    path: path,
    name: name,
    child: child,
    onExit: onExit,
    redirect: redirect,
    transition: transition,
    pageBuilder: pageBuilder,
    parentNavigatorKey: parentNavigatorKey,
    guards: [...inheritedGuards, ...guards],
  );
}

/// Extension for [ModuleRoute] to support guard propagation.
///
/// This wraps the inner [module] with a [GuardModuleDecorator], which
/// ensures that [inheritedGuards] are applied recursively to all
/// nested child routes inside that module.
extension ModuleRouteExtensions on ModuleRoute {
  ModuleRoute withInjectedGuards(List<IGuard> inheritedGuards) => ModuleRoute(
    path: path,
    name: name,
    redirect: redirect,
    parentNavigatorKey: parentNavigatorKey,
    module: GuardModuleDecorator(module: module, guards: inheritedGuards),
  );
}

/// Extension methods for [RedirectRoute] to support guard injection.
///
/// This is primarily used by [propagateGuards] to automatically apply
/// parent-level guards to nested [RedirectRoute] instances.
///
/// ### Behavior
/// - Creates a new [RedirectRoute] with the same properties as the original.
/// - Combines the [inheritedGuards] from the parent with the route's own [guards].
/// - Guard execution order:
///   1. Inherited guards (from parent modules or shells)
///   2. Local guards (declared directly on this route)
///
/// ### Example
/// ```dart
/// final guardedRedirect = RedirectRoute(
///   path: '/old/:id',
///   redirect: (context, state) {
///     final id = state.pathParameters['id'];
///     return '/new/$id';
///   },
/// );
///
/// final propagated = guardedRedirect.withInjectedGuards([AuthGuard()]);
///
/// // Now both AuthGuard and the local guards (if any) will run
/// // before applying the redirect.
/// ```
///
/// This ensures that redirect-only routes respect the same
/// guard propagation rules as [ChildRoute], [ModuleRoute],
/// and [ShellModuleRoute].
extension RedirectRouteExtensions on RedirectRoute {
  /// Returns a copy of this [RedirectRoute] with additional [inheritedGuards].
  ///
  /// The new route has the same [path], [name], and [redirect] callback,
  /// but its [guards] list is extended to include both existing and inherited guards.
  RedirectRoute withInjectedGuards(List<IGuard> inheritedGuards) =>
      RedirectRoute(
        path: path,
        name: name,
        redirect: redirect,
        guards: [...inheritedGuards, ...guards],
      );
}

/// Extension for [ShellModuleRoute] to support guard propagation.
///
/// Unlike [StatefulShellModuleRoute], the routes here are already flat,
/// so we can safely delegate to [propagateGuards].
extension ShellModuleRouteExtensions on ShellModuleRoute {
  ShellModuleRoute withInjectedGuards(List<IGuard> inheritedGuards) =>
      ShellModuleRoute(
        builder: builder,
        redirect: redirect,
        observers: observers,
        pageBuilder: pageBuilder,
        navigatorKey: navigatorKey,
        parentNavigatorKey: parentNavigatorKey,
        restorationScopeId: restorationScopeId,
        routes: propagateGuards(routes: routes, guards: inheritedGuards),
      );
}

/// Extension for [StatefulShellModuleRoute] to support guard propagation.
///
/// This extension ensures that guards defined at higher levels are injected
/// into each branch (which can be [ChildRoute], [ModuleRoute], or another shell).
/// Because branches are heterogeneous, we cannot just call [propagateGuards].
extension StatefulShellModuleRouteExtensions on StatefulShellModuleRoute {
  StatefulShellModuleRoute withInjectedGuards(List<IGuard> inheritedGuards) {
    final injected =
        routes.map<IRoute>((route) {
          if (route is ChildRoute) {
            return route.withInjectedGuards(inheritedGuards);
          }
          if (route is ModuleRoute) {
            return route.withInjectedGuards(inheritedGuards);
          }
          if (route is ShellModuleRoute) {
            return route.withInjectedGuards(inheritedGuards);
          }
          if (route is StatefulShellModuleRoute) {
            return route.withInjectedGuards(inheritedGuards);
          }
          return route;
        }).toList();

    return StatefulShellModuleRoute(
      builder: builder,
      routes: injected,
      parentNavigatorKey: parentNavigatorKey,
      restorationScopeId: restorationScopeId,
    );
  }
}
