import 'package:modugo/src/guard.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/decorators/guard_module_decorator.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
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
    routePattern: routePattern,
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
    routePattern: routePattern,
    parentNavigatorKey: parentNavigatorKey,
    module: GuardModuleDecorator(module: module, guards: inheritedGuards),
  );
}

/// Extension for [ShellModuleRoute] to support guard propagation.
///
/// Unlike [StatefulShellModuleRoute], the routes here are already flat,
/// so we can safely delegate to [propagateGuards].
extension ShellModuleRouteExtensions on ShellModuleRoute {
  ShellModuleRoute withInjectedGuards(List<IGuard> inheritedGuards) =>
      ShellModuleRoute(
        binds: binds,
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
      routePattern: routePattern,
      parentNavigatorKey: parentNavigatorKey,
      restorationScopeId: restorationScopeId,
    );
  }
}
