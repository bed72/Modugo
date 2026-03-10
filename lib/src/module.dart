import 'package:flutter/widgets.dart' hide Container;
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/container/container.dart';

import 'package:modugo/src/mixins/binder_mixin.dart';
import 'package:modugo/src/mixins/dsl_mixin.dart';
import 'package:modugo/src/mixins/router_mixin.dart';

import 'package:modugo/src/routes/factory_route.dart';

/// A set of module types that have been registered globally,
/// used to ensure the same module is not bound more than once.
final Set<Type> _registered = {};

/// For testing: allows checking and manipulating the registered modules set.
@visibleForTesting
Set<Type> get registeredForTest => _registered;

/// Abstract base class for a "module" (feature) within the application.
///
/// A [Module] defines:
/// - [imports()]: other modules it depends on. The `binds()` of imported
///   modules are executed before the current module's `binds()`.
/// - [routes()]: the route tree exposed by this module (e.g., [child],
///   [module], [shell], [statefulShell]).
/// - [binds()]: registers the module's dependencies in [Container] (via [i]).
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
/// Lifecycle:
/// - Use [initState()] for setup when the module becomes active.
/// - Use [dispose()] to clean up resources. Calling `super.dispose()` will
///   automatically dispose all bindings registered by this module and allow
///   re-registration if the user navigates back.
///
/// Example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   List<IBinder> imports() => [SharedModule()];
///
///   @override
///   List<IRoute> routes() => [
///     child(path: '/', child: (context, state) => const HomePage()),
///   ];
///
///   @override
///   void binds() {
///     i.addLazySingleton<HomeController>(
///       () => HomeController(),
///       onDispose: (ctrl) => ctrl.dispose(),
///     );
///     i.addSingleton<ApiClient>(() => ApiClient());
///   }
/// }
/// ```
abstract class Module with IBinder, IDsl, IRouter {
  /// Shortcut to access the [Container] used for dependency injection.
  Container get i => Modugo.container;

  /// The tag used to scope this module's bindings in the container.
  ///
  /// Defaults to the runtime type name. All bindings registered in [binds()]
  /// are associated with this tag, enabling scoped disposal via [dispose()].
  String get tag => runtimeType.toString();

  /// Called when the module is initialized.
  ///
  /// Use this method to perform any setup required when the module
  /// becomes active, such as initializing internal state, registering
  /// listeners, or preparing resources.
  ///
  /// **Note:** Subclasses should call `super.initState()` if they
  /// override this method to ensure proper module lifecycle behavior.
  void initState() {}

  /// Called when the module is being disposed.
  ///
  /// Disposes all bindings registered by this module (calling their
  /// `onDispose` callbacks in reverse registration order) and removes
  /// the module from the registry, allowing re-registration if the
  /// user navigates back.
  ///
  /// **Important:** Subclasses should call `super.dispose()` to ensure
  /// proper cleanup. Custom cleanup logic should run **before** `super.dispose()`.
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   myCustomCleanup();
  ///   super.dispose();
  /// }
  /// ```
  @mustCallSuper
  void dispose() {
    Modugo.container.disposeModule(tag);
    _registered.remove(runtimeType);
  }

  /// Configures and returns the list of [RouteBase]s defined by this module.
  ///
  /// This method is responsible for:
  /// - registering binds for the module (if not already active)
  /// - creating and combining child, shell, and module routes
  ///
  /// Returns a combined list of all routes defined by this module and its nested structures.
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
  /// - Sets [Container.activeTag] before calling [binds()] so all
  ///   registrations are associated with the module's tag.
  void _configureBinders({IBinder? binder}) {
    final target = binder ?? this;

    if (_registered.contains(target.runtimeType)) {
      Logger.module('${target.runtimeType} skipped (already registered)');
      return;
    }

    for (final imported in target.imports()) {
      _configureBinders(binder: imported);
    }

    Modugo.container.activeTag = (target is Module)
        ? target.tag
        : target.runtimeType.toString();
    target.binds();
    Modugo.container.activeTag = null;

    _registered.add(target.runtimeType);

    Logger.module('${target.runtimeType} binds registered');
  }
}
