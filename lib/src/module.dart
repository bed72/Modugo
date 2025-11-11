// ignore_for_file: use_build_context_synchronously

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';

import 'package:modugo/src/mixins/binder_mixin.dart';
import 'package:modugo/src/mixins/helper_mixin.dart';
import 'package:modugo/src/mixins/router_mixin.dart';

import 'package:modugo/src/routes/factory_route.dart';

/// A set of module types that have been registered globally,
/// used to ensure the same module is not bound more than once.
final Set<Type> _modulesRegistered = {};

/// Abstract base class for a "module" (feature) within the application.
///
/// A [Module] defines:
/// - [imports()]: other modules it depends on. The `binds()` of imported
///   modules are executed before the current module's `binds()`.
/// - [routes()]: the route tree exposed by this module (e.g., [child],
///   [module], [shell], [statefulShell]).
/// - [binds()]: registers the module's dependencies in [GetIt] (via [i]).
///
/// Behavior:
/// - When [configureRoutes()] is called, the framework registers — **only once
///   per module type** — the `binds()` of the current module **and** all
///   imported modules, then sets up the route list.
/// - Dependency registration is idempotent: if a module has already been
///   registered, its `binds()` will not be executed again.
/// - Even if a module does not expose its own routes, if it appears in
///   [imports()], its `binds()` will still be executed.
///
/// Customization:
/// - Use [initState()] and [dispose()] to manage the module's internal state if
///   necessary.
/// - The injection instance is accessible via [i] (shortcut to
///   `GetIt.instance`).
///
/// Example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   List<IBinder> imports() => [SharedModule()];
///
///   @override
///   List<IRoute> routes() => [
///     route(path: '/', child: (context, state) => const HomePage()),
///   ];
///
///   @override
///   void binds() {
///     i
///       ..registerLazySingleton<HomeController>(() => HomeController())
///       ..registerSingleton<ApiClient>(ApiClient());
///   }
/// }
/// ```
abstract class Module with IBinder, IHelper, IRouter {
  /// Shortcut to access the global GetIt instance used for dependency injection.
  /// Provides direct access to registered services and singletons.
  GetIt get i => GetIt.instance;

  /// Called when the module is initialized.
  ///
  /// Use this method to perform any setup required when the module
  /// becomes active, such as initializing internal state, registering
  /// listeners, or preparing resources.
  ///
  /// This method is automatically called by the framework when the
  /// module is first instantiated or when its routes become active.
  ///
  /// **Note:** Subclasses should call `super.initState()` if they
  /// override this method to ensure proper module lifecycle behavior.
  void initState() {}

  /// Called when the module is being disposed.
  ///
  /// Use this method to clean up resources, cancel subscriptions,
  /// dispose internal state, and remove any module-specific event
  /// listeners.
  ///
  /// This method is automatically called by the framework when the
  /// module is no longer needed or when its routes are removed from
  /// the navigation stack.
  ///
  /// **Important:** Subclasses should call `super.dispose()` if they
  /// override this method to ensure that all module-level resources,
  /// including event channels and subscriptions, are properly released.
  void dispose() {}

  /// Configures and returns the list of [RouteBase]s defined by this module.
  ///
  /// This method is responsible for:
  /// - registering binds for the module (if not already active)
  /// - creating and combining child, shell, and module routes
  /// - optionally logging the final set of registered route paths when diagnostics are enabled
  ///
  /// Returns a combined list of all routes defined by this module and its nested structures.
  ///
  /// Example:
  /// ```dart
  /// final routes = module.configureRoutes();
  /// ```
  List<RouteBase> configureRoutes() {
    _configureBinders();

    return FactoryRoute.from(routes());
  }

  /// Registers this module and all its imported modules recursively.
  ///
  /// Behavior:
  /// - Imported modules are always registered **before** the current one.
  /// - Each module type is registered at most once; subsequent attempts
  ///   are skipped and logged.
  /// - Prevents cyclic imports by keeping track of already-registered types.
  /// - Executes the [binds] method of each module to register its
  ///   dependency injection bindings into [GetIt].
  ///
  /// [binder] Optional module to register explicitly. If `null`, the current
  ///   module (`this`) will be used.
  void _configureBinders({IBinder? binder}) async {
    final targetBinder = binder ?? this;

    if (_modulesRegistered.contains(targetBinder.runtimeType)) {
      Logger.module('${targetBinder.runtimeType} skipped (already registered)');
      return;
    }

    for (final imported in targetBinder.imports()) {
      _configureBinders(binder: imported);
    }

    targetBinder.binds();
    _modulesRegistered.add(targetBinder.runtimeType);

    Logger.module('${targetBinder.runtimeType} binds registered');
  }
}
