import 'dart:async';

import 'package:modugo/modugo.dart';
import 'package:modugo/src/routes/models/route_access_model.dart';

/// Internal class responsible for managing the lifecycle of modules and their binds.
///
/// The [Manager] tracks:
/// - which modules are currently active
/// - when and how binds should be registered or disposed
/// - route-to-module associations for cleanup
///
/// It is automatically used by [ModugoConfiguration], and should not be instantiated manually.
final class Manager implements IManager {
  Timer? _timer;
  Module? _module;

  final Map<Type, int> _bindReferences = {};
  final Map<Module, Set<Type>> _moduleTypes = {};
  final Map<Module, List<RouteAccessModel>> _activeRoutes = {};

  /// A private static instance used to implement the singleton pattern.
  ///
  /// This ensures that only one instance of [Manager] exists throughout
  /// the application's lifecycle.
  static final Manager _instance = Manager._();

  /// Private named constructor used internally to create the singleton instance.
  ///
  /// Prevents external instantiation of the [Manager] class.
  Manager._();

  /// Factory constructor that returns the singleton instance of [Manager].
  ///
  /// This provides global access to the single [Manager] instance,
  /// ensuring consistent state and behavior across the app.
  factory Manager() => _instance;

  /// Returns the currently active root [Module] registered via [Modugo.configure].
  ///
  /// This is the top-level module that defines the initial routes and binds.
  /// It is set once during application initialization and used as the base context
  /// for resolving nested module dependencies.
  @override
  Module? get module => _module;

  /// Sets the root [Module] for the application.
  ///
  /// This is usually assigned during [Modugo.configure] and represents
  /// the top-level module in the modular hierarchy.
  @override
  set module(Module? module) {
    _module = module;
  }

  /// Returns the root [Module] instance that was registered via [Modugo.configure].
  ///
  /// This is the top-level module for the app and is used internally
  /// by features like [Modugo.matchRoute] and lifecycle control.
  ///
  /// Throws a [StateError] if called before [Modugo.configure].
  @override
  Module get rootModule {
    final root = _module;
    if (root == null) {
      throw StateError('Modugo has not been configured with a root Module.');
    }

    return root;
  }

  /// Returns a map of registered bind types and their reference counts.
  ///
  /// This is used internally to track how many modules are using each bind
  /// and to ensure that shared binds are only disposed when no longer needed.
  @override
  Map<Type, int> get bindReferences => _bindReferences;

  /// Returns `true` if the given [module] is currently active (has at least one route registered).
  ///
  /// A module is considered active if it's associated with at least one route
  /// in the internal [_activeRoutes] registry.
  @override
  bool isModuleActive(Module module) => _activeRoutes.containsKey(module);

  /// Returns a list of currently active [RouteAccessModel]s associated with the given [module].
  ///
  /// Each entry tracks an active route path and optional branch, allowing cleanup
  /// or analysis of module usage across routes.
  @override
  List<RouteAccessModel> getActiveRoutesFor(Module module) =>
      _activeRoutes[module]?.toList() ?? [];

  /// Registers all binds from the application-level [module] if not already set.
  ///
  /// This method is called once during [Modugo.configure] to establish the root module.
  /// If the module has already been assigned, it does nothing.
  ///
  /// It also delegates to [registerBindsIfNeeded] to ensure binds are properly registered.
  @override
  void registerBindsAppModule(Module module) {
    if (_module != null) return;

    _module = module;
    registerBindsIfNeeded(module);
  }

  /// Registers binds for the given [module] only if it is not already active.
  ///
  /// Ensures that:
  /// - all binds in the module and its imports are registered
  /// - the module is tracked as active for future cleanup
  ///
  /// If the module is already active, it is skipped to avoid duplicate bindings.
  ///
  /// Logs the module registration if [Modugo.debugLogDiagnostics] is enabled.
  @override
  void registerBindsIfNeeded(Module module) {
    if (_activeRoutes.containsKey(module)) return;

    _registerBinds(module);
    _activeRoutes[module] = [];

    Logger.module('${module.runtimeType} UP');
  }

  /// Registers a route [path] as active for the given [module].
  ///
  /// This is used to track which routes are currently associated with a module,
  /// enabling precise control over when its binds can be safely disposed.
  ///
  /// Optionally, a [branch] can be provided to differentiate navigation tabs
  /// in `StatefulShellModuleRoute`.
  @override
  void registerRoute(String path, Module module, {String? branch}) {
    _activeRoutes.putIfAbsent(module, () => []);
    _activeRoutes[module]?.add(RouteAccessModel(path, branch));
  }

  /// Unregisters a previously tracked [path] from the given [module].
  ///
  /// If the module is not the root module, and no more active routes remain,
  /// its binds are scheduled for disposal after [disposeMilisenconds].
  ///
  /// Uses a [Timer] to allow for navigation delays before cleanup,
  /// preventing premature disposal during quick route switches.
  @override
  void unregisterRoute(String path, Module module, {String? branch}) {
    if (module == _module) return;

    _activeRoutes[module]?.removeWhere(
      (r) => r.path == path && r.branch == branch,
    );

    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: disposeMilisenconds), () {
      if (_activeRoutes[module]?.isEmpty ?? true) unregisterBinds(module);
      _timer?.cancel();
    });
  }

  /// Unregisters all binds associated with the given [module], if it is no longer active.
  ///
  /// This method is a key part of the Modugo lifecycle management.
  /// It ensures that:
  /// - the root module is never disposed
  /// - the module has no remaining active routes
  /// - all registered bind types from the module are reference-decremented and disposed if unused
  ///
  /// If [Modugo.debugLogDiagnostics] is enabled, the unregistration is logged.
  @override
  void unregisterBinds(Module module) {
    if (_module == module) return;
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (module.persistent) {
      Logger.module('${module.runtimeType} PERSISTENT');

      return;
    }

    Logger.module('${module.runtimeType} DOWN');

    final types = _moduleTypes.remove(module) ?? {};

    for (final type in types) {
      _decrementBindReference(type);
    }

    _activeRoutes.remove(module);
  }

  void _registerBinds(Module module) {
    final typesForModule = <Type>{};

    final before = Injector().registeredTypes;
    module.binds(Injector());
    final after = Injector().registeredTypes;

    final newTypes = after.difference(before);
    for (final type in newTypes) {
      _incrementBindReference(type);
      typesForModule.add(type);
    }

    for (final imported in module.imports()) {
      final beforeImport = Injector().registeredTypes;
      imported.binds(Injector());
      final afterImport = Injector().registeredTypes;

      final importedTypes = afterImport.difference(beforeImport);
      for (final type in importedTypes) {
        _incrementBindReference(type);
        typesForModule.add(type);
      }
    }

    _moduleTypes[module] = typesForModule;
  }

  void _incrementBindReference(Type type) {
    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
  }

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        Injector().disposeByType(type);
      }
    }
  }
}
