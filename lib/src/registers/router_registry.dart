// coverage:ignore-file

import 'package:modugo/src/interfaces/route_interface.dart';

/// Mixin for declaring navigation routes exposed by a module.
///
/// A [RouterRegistry] defines the routing surface of a module,
/// independent of dependency injection concerns.
/// This keeps the responsibility of *what screens/pages a module
/// provides* separate from *how its dependencies are wired*.
///
/// ### Responsibilities
/// - Declares the list of routes that belong to this module.
/// - Routes can be of different types, such as:
///   - [ChildRoute]: a simple leaf route mapped to a widget.
///   - [ModuleRoute]: a nested module entry point.
///   - [ShellModuleRoute]: a container route (e.g. bottom navigation).
///   - [StatefulShellModuleRoute]: a stateful shell route with
///     independent navigation stacks.
/// - Supports nested and composable module structures by allowing
///   routes to reference other modules.
///
/// ### Behavior
/// - By default, [routes] returns an empty list, meaning the module
///   does not expose any routes.
/// - Subclasses/modules are expected to override [routes] and
///   declare their own navigation structure.
/// - The Modugo framework collects these routes during
///   [Module.configureRoutes] and composes them into the application's
///   global [GoRouter] configuration.
///
/// ### Example
/// ```dart
/// final class ProductsModule extends Module with RouterRegistry {
///   @override
///   List<IRoute> routes() => [
///     ChildRoute(
///       path: '/products',
///       child: (_, __) => const ProductsPage(),
///     ),
///     ModuleRoute(
///       path: '/product',
///       module: ProductDetailModule(),
///     ),
///   ];
/// }
/// ```
///
/// In this example, the [ProductsModule] exposes both a direct page
/// (`/products`) and a nested submodule (`/product`).
///
/// See also:
/// - [BinderRegistry] for dependency injection bindings.
/// - [Module] which combines [RouterRegistry] and [BinderRegistry].
mixin RouterRegistry {
  /// List of navigation routes this module exposes.
  ///
  /// Override this method to declare which routes belong to this module.
  /// Defaults to an empty list.
  List<IRoute> routes() => const [];
}
