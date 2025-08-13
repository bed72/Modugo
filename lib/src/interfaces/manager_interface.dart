// coverage:ignore-file

import 'package:modugo/src/module.dart';

import 'package:modugo/src/models/route_access_model.dart';

/// Interface that defines the contract for managing module lifecycles and route bindings
/// within the Modugo system.
///
/// The [IManager] is responsible for:
/// - tracking the current active [Module]
/// - managing reference counts of registered [Bind]s
/// - handling registration and disposal of route/module associations
///
/// Typically used internally by Modugo to orchestrate route-aware
/// dependency injection and cleanup.
abstract interface class IManager {
  /// The currently active [Module], typically the root application module.
  Module? get module;

  /// Sets the currently active [Module].
  ///
  /// Usually assigned during [Modugo.configure].
  set module(Module? module);

  /// Returns the root [Module] instance that was registered via [Modugo.configure].
  ///
  /// This is the top-level module for the app and is used internally
  /// by features like [Modugo.matchRoute] and lifecycle control.
  ///
  /// Throws a [StateError] if called before [Modugo.configure].
  Module get rootModule;

  /// Returns `true` if the given [module] has already been activated.
  ///
  /// Example:
  /// ```dart
  /// if (!manager.isModuleActive(myModule)) {
  ///   manager.registerBindsAppModule(myModule);
  /// }
  /// ```
  bool isModuleActive(Module module);

  /// Associates a route path [route] with a [module] for lifecycle tracking.
  ///
  /// This enables the manager to later unregister the module
  /// when the route is popped or no longer active.
  void registerRoute(String route, Module module);

  /// Removes a route-module association from tracking.
  ///
  /// Called when a route is disposed or removed from the navigation stack.
  void unregisterRoute(String route, Module module);

  /// Returns a list of all active [RouteAccessModel]s for the given [module].
  ///
  /// Each [RouteAccessModel] tracks the path and entry timestamp for a route.
  List<RouteAccessModel> getActiveRoutesFor(Module module);
}
