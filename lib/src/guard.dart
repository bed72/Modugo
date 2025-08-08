// coverage:ignore-file
// ignore_for_file: pattern_never_matches_value_type

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';

import 'package:modugo/src/extensions/guard_extension.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// Injects a list of guards into a given route module.
///
/// Depending on the runtime type of [route], this function casts it to the appropriate
/// subclass and calls `withInjectedGuards` to add the [guards].
/// If the route type is not recognized, it returns the route unchanged.
///
/// Supported route types:
/// - [ChildRoute]
/// - [ModuleRoute]
/// - [ShellModuleRoute]
///
/// [route]: The route module into which guards will be injected.
/// [parentGuards]: The list of guards to inject.
///
/// Returns the same route type instance with the [guards] injected.
IModule _injectGuards(IModule route, List<IGuard> guards) =>
    route is ChildRoute ? route.withInjectedGuards(guards) : route;

/// Injects a list of guards into each route module in the given list.
///
/// Iterates through the [routes] list and applies [_injectGuards] to inject
/// the provided [guards] into each route.
///
/// [routes]: The list of route modules to inject guards into.
/// [parentGuards]: The list of guards to inject into each route.
///
/// Returns a new list of route modules with guards injected.
List<IModule> propagateGuards({
  required List<IGuard> guards,
  required List<IModule> routes,
}) => routes.map((route) => _injectGuards(route, guards)).toList();
