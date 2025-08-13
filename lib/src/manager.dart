import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

/// Internal class responsible for managing the lifecycle of modules.
///
/// The [Manager] tracks:
/// - which modules are currently active
/// - route-to-module associations for cleanup
///
/// It is automatically used by [ModugoConfiguration], and should not be instantiated manually.
final class Manager implements IManager {
  /// The root module configured for the application.
  /// Used as the entry point for route registration and dependency injection.
  Module? _module;

  /// Tracks all currently active routes per module.
  /// Each entry maps a [Module] to a list of route paths that are currently registered/active.
  final Map<Module, List<String>> _activeRoutes = {};

  /// Tracks the types registered by each module to allow unregistering from GetIt.
  final Map<Module, Set<Type>> _registeredTypes = {};

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

  /// Returns `true` if the given [module] is currently active (has at least one route registered).
  ///
  /// A module is considered active if it's associated with at least one route
  /// in the internal [_activeRoutes] registry.
  @override
  bool isModuleActive(Module module) => _activeRoutes.containsKey(module);

  /// Returns a list of currently active [String]s associated with the given [module].
  ///
  /// Each entry tracks an active route path and optional branch, allowing cleanup
  /// or analysis of module usage across routes.
  @override
  List<String> getActiveRoutesFor(Module module) =>
      _activeRoutes[module]?.toList() ?? [];

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

  /// Registers a route [path] as active for the given [module].
  ///
  /// This is used to track which routes are currently associated with a module,
  /// enabling precise control over when its binds can be safely disposed.
  ///
  @override
  void registerRoute(String path, Module module) {
    _activeRoutes.putIfAbsent(module, () => []);
    _activeRoutes[module]?.add(path);

    _registeredTypes.putIfAbsent(module, () => {});
    _registeredTypes[module]!.add(module.runtimeType);
  }

  /// Unregisters a previously tracked [path] from the given [module].
  ///
  /// If the module is not the root module, and no more active routes remain,
  /// the module is fully disposed.
  @override
  void unregisterRoute(String path, Module module) {
    if (module == _module) return;

    _activeRoutes[module]?.removeWhere((p) => p == path);

    if ((_activeRoutes[module]?.isEmpty ?? true)) {
      _disposeModule(module);
    }
  }

  void _disposeModule(Module module) {
    _activeRoutes.remove(module);
    _registeredTypes.remove(module);
  }
}
