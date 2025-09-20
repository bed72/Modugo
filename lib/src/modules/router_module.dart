// coverage:ignore-file

import 'package:flutter/foundation.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/registers/binder_registry.dart';

/// Base class for modules that provide only navigation routes,
/// without declaring any dependency injection bindings.
///
/// A [RouterModule] is useful when you want to group and expose
/// application routes, but the module itself does not contribute
/// services or repositories to the dependency injection container.
///
/// ### Behavior
/// - Overrides [binds] to do nothing (no DI registrations).
/// - Overrides [imports] to return an empty list (no DI imports).
/// - Still supports [routes] and [configureRoutes], inherited from [Module].
///
/// ### Example
/// ```dart
/// final class HomeModule extends RouterModule {
///   @override
///   List<IRoute> routes() => [
///     ChildRoute(
///       path: '/home',
///       child: (_, _) => const HomePage(),
///     ),
///     ChildRoute(
///       path: '/settings',
///       child: (_, _) => const SettingsPage(),
///     ),
///   ];
/// }
///
/// final class AppModule extends Module {
///   @override
///   List<BinderRegistry> imports() => [CoreModule()];
///
///   @override
///   List<IRoute> routes() => [
///     ModuleRoute(module: HomeModule()), // only provides routes
///   ];
/// }
/// ```
///
/// In this example, [HomeModule] encapsulates the navigation routes
/// for the "home" feature of the app, but it does not define or
/// register any bindings into the DI container.
abstract class RouterModule extends Module {
  @override
  @nonVirtual
  void binds() {}

  @override
  @nonVirtual
  List<BinderRegistry> imports() => const [];
}
