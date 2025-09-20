// coverage:ignore-file

import 'package:flutter/foundation.dart';

import 'package:modugo/src/modules/module.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

/// Base class for modules that provide only dependency injection bindings,
/// without exposing any navigation routes.
///
/// A [BinderModule] is useful when you want to group and register
/// services, repositories, controllers, or any other dependencies into
/// the global [GetIt] container, but the module itself does not define
/// or expose any UI routes.
///
/// ### Behavior
/// - Overrides [routes] to always return an empty list (`[]`).
/// - Still supports [binds] and [imports], inherited from [Module].
/// - When registered, its dependencies are guaranteed to be
///   initialized exactly once, even if imported by multiple modules.
///
/// ### Example
/// ```dart
/// final class CoreModule extends BinderModule {
///   @override
///   void binds() {
///     i.registerLazySingleton<ApiClient>(() => ApiClient());
///     i.registerLazySingleton<AuthRepository>(
///       () => AuthRepositoryImpl(i.get<ApiClient>()),
///     );
///   }
/// }
///
/// final class AppModule extends Module {
///   @override
///   List<BinderRegistry> imports() => [CoreModule()];
///
///   @override
///   List<IRoute> routes() => [
///     ChildRoute(path: '/', child: (_, __) => const HomePage()),
///   ];
/// }
/// ```
///
/// In this example, [CoreModule] encapsulates all dependency bindings
/// for the app, while [AppModule] imports it to reuse its services and
/// defines the navigation routes separately.
abstract class BinderModule extends Module {
  @override
  @nonVirtual
  List<IRoute> routes() => const [];
}
