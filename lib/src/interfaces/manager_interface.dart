// coverage:ignore-file

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/models/route_access_model.dart';

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

  /// A map tracking how many times each [Bind] type has been registered.
  ///
  /// This is used to support reference counting and safe disposal.
  Map<Type, int> get bindReferences;

  /// Returns `true` if the given [module] has already been activated.
  ///
  /// Example:
  /// ```dart
  /// if (!manager.isModuleActive(myModule)) {
  ///   manager.registerBindsAppModule(myModule);
  /// }
  /// ```
  bool isModuleActive(Module module);

  /// Unregisters all [Bind]s associated with the given [module].
  ///
  /// This includes local binds and imported modules.
  ///
  /// Automatically handles reference count checks.
  void unregisterBinds(Module module);

  /// Registers all binds for a [module] if they haven't been registered yet.
  ///
  /// This is typically used for dynamic or nested module resolution.
  void registerBindsIfNeeded(Module module);

  /// Registers all binds for the top-level application [module].
  ///
  /// Called once during initial Modugo setup.
  void registerBindsAppModule(Module module);

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
