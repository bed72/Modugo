// coverage:ignore-file

import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';

/// Extension that provides a unified entry point for resolving
/// both dependency bindings and route configuration for a [Module].
///
/// This is a **convenience helper** that executes:
/// 1. `configureBinders()` — to recursively register all module-level
///    and imported dependencies in GetIt.
/// 2. `configureRoutes()` — to build the final list of [RouteBase]s
///    (including `ChildRoute`, `ModuleRoute`, `AliasRoute`, `ShellModuleRoute`,
///    and `StatefulShellModuleRoute`).
///
/// The result is a fully configured, dependency-injected module,
/// returning a ready-to-use list of routes for [GoRouter].
///
///
/// ### 🧩 Why use it?
/// Instead of calling both methods manually:
/// ```dart
/// module.configureBinders();
/// final routes = module.configureRoutes();
/// ```
///
/// You can simply do:
/// ```dart
/// final routes = module.resolve();
/// ```
///
/// This ensures **imports, binds, and route composition** all occur
/// in the correct order, producing a consistent and deterministic
/// configuration flow for your modular app.
///
///
/// ### 🧠 Behavior
/// - Imported modules are always registered before the current module.
/// - Each module type is registered only once globally.
/// - All [IBinder] instances have their `binds()` executed exactly once.
/// - The returned list can be safely passed to `GoRouter(routes: ...)`.
///
///
/// ### ✅ Example
/// ```dart
/// final routes = module.resolve();
///
/// final router = GoRouter(
///   routes: routes,
///   initialLocation: '/',
/// );
/// ```
///
/// Equivalent to:
/// ```dart
/// module.configureBinders();
/// final routes = module.configureRoutes();
/// ```
extension ModuleConfigurator on Module {
  /// Registers all dependencies (via [configureBinders]) and
  /// builds all defined routes (via [configureRoutes]) for this module.
  ///
  /// Returns a complete, ready-to-use list of [RouteBase]s suitable
  /// for direct usage in [GoRouter].
  List<RouteBase> resolve() {
    configureBinders();
    return configureRoutes();
  }
}
