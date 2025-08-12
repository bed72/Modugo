import 'dart:async';

import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';

import 'package:modugo/src/managers/queue_manager.dart';
import 'package:modugo/src/routes/models/route_access_model.dart';

/// Internal class responsible for managing the lifecycle of modules and their binds.
///
/// The [InjectorManager] tracks:
/// - which modules are currently active
/// - when and how binds should be registered or disposed
/// - route-to-module associations for cleanup
///
/// It is automatically used by [ModugoConfiguration], and should not be instantiated manually.
final class InjectorManager implements IInjectorManager {
  Timer? _timer;
  Module? _module;

  final injector = Injector();

  final QueueManager _queueManager = QueueManager.instance;

  final Map<Type, int> _bindReferences = {};
  final Set<Module> _registeringModules = {};
  final Map<Module, Set<Type>> _moduleTypes = {};
  final Map<Module, List<RouteAccessModel>> _activeRoutes = {};

  /// A private static instance used to implement the singleton pattern.
  ///
  /// This ensures that only one instance of [InjectorManager] exists throughout
  /// the application's lifecycle.
  static final InjectorManager _instance = InjectorManager._();

  /// Private named constructor used internally to create the singleton instance.
  ///
  /// Prevents external instantiation of the [InjectorManager] class.
  InjectorManager._();

  /// Factory constructor that returns the singleton instance of [InjectorManager].
  ///
  /// This provides global access to the single [InjectorManager] instance,
  /// ensuring consistent state and behavior across the app.
  factory InjectorManager() => _instance;

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
  ///
  /// The registration is enqueued to avoid concurrent bind registration issues.
  @override
  Future<void> registerBindsAppModule(Module module) async {
    if (_module != null) return;

    await _queueManager.enqueue(() async {
      _module = module;
      await registerBindsIfNeeded(module);
    });
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
  ///
  /// The registration is enqueued to guarantee sequential execution.
  @override
  Future<void> registerBindsIfNeeded(Module module) async {
    if (_activeRoutes.containsKey(module) ||
        _registeringModules.contains(module)) {
      return;
    }

    _registeringModules.add(module);
    _activeRoutes[module] = [];

    await _queueManager.enqueue(() async {
      try {
        await _registerBinds(module);
        Logger.module('${module.runtimeType} UP');
      } finally {
        _registeringModules.remove(module);
      }
    });
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
      if (_activeRoutes[module]?.isEmpty ?? true) {
        unregisterBinds(module);
      }
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
  ///
  /// The unregistration is enqueued to ensure sequential and safe disposal.
  @override
  Future<void> unregisterBinds(Module module) async {
    if (_module == module) return;
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    await _queueManager.enqueue(() async {
      if (module.persistent) {
        Logger.module('${module.runtimeType} PERSISTENT');
        return;
      }

      Logger.module('${module.runtimeType} DOWN');

      final types = _moduleTypes.remove(module) ?? {};

      for (final type in types) {
        decrementBindReference(type);
      }

      _activeRoutes.remove(module);
    });
  }

  /// Registers binds from the given [module] and its imported modules.
  ///
  /// This method tracks which bind types belong to the module for
  /// future reference counting and disposal.
  ///
  /// This method is synchronous and expects the binds method in modules to be synchronous.
  Future<void> _registerBinds(Module module) async {
    final typesForModule = <Type>{};

    final before = injector.registeredTypes;

    // Await binds que pode ser Future ou void
    await Future.value(module.binds(injector));

    final after = injector.registeredTypes;

    final newTypes = after.difference(before);
    for (final type in newTypes) {
      incrementBindReference(type);
      typesForModule.add(type);
    }

    final importedModules = await Future.value(module.imports());

    for (final imported in importedModules) {
      final beforeImport = injector.registeredTypes;
      await Future.value(imported.binds(injector));
      final afterImport = injector.registeredTypes;

      final importedTypes = afterImport.difference(beforeImport);
      for (final type in importedTypes) {
        incrementBindReference(type);
        typesForModule.add(type);
      }
    }

    _moduleTypes[module] = typesForModule;
  }

  @visibleForTesting
  void incrementBindReference(Type type) {
    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
  }

  @visibleForTesting
  void decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        injector.disposeByType(type);
      }
    }
  }
}
