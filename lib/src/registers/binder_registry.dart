// coverage:ignore-file

import 'package:modugo/src/modules/module.dart';

/// Mixin for declaring dependency injection bindings of a module.
///
/// A [BinderRegistry] defines *what services or dependencies a module
/// provides* and *what other modules it depends on*.
/// This separates the concern of dependency injection from routing,
/// ensuring a clear division of responsibilities inside a [Module].
///
/// ### Responsibilities
/// - Declares the bindings (services, controllers, repositories, etc.)
///   that this module contributes to the global dependency injection container.
/// - Specifies imported modules, enabling modular composition where
///   one module can depend on and reuse the bindings of others.
/// - Ensures that imports are processed recursively before the current
///   module’s own bindings are registered, avoiding missing dependencies.
///
/// ### Behavior
/// - By default, [binds] is a no-op and [imports] returns an empty list,
///   meaning the module has no dependencies and provides no bindings.
/// - Subclasses/modules override [binds] to register their dependencies
///   using the [GetIt] instance (accessible via `GetIt.instance` or
///   through the `i` getter in [Module]).
/// - The Modugo framework ensures that each module’s [binds] is executed
///   at most once per module type, even if imported by multiple modules.
///
/// ### Example
/// ```dart
/// final class AuthModule with BinderRegistry {
///   @override
///   void binds() {
///     final i = GetIt.instance;
///     i.registerLazySingleton<AuthRepository>(
///       () => AuthRepositoryImpl(i.get<ApiClient>()),
///     );
///   }
///
///   @override
///   List<BinderRegistry> imports() => [CoreModule()];
/// }
/// ```
///
/// In this example, the [AuthModule] provides an [AuthRepository] binding
/// and declares a dependency on [CoreModule] to reuse its bindings.
///
/// See also:
/// - [RouterRegistry] for route declarations.
/// - [Module] which combines [BinderRegistry] and [RouterRegistry].
mixin BinderRegistry {
  /// Registers all dependency injection bindings for this module.
  ///
  /// Override this method to declare your dependencies using the [GetIt].
  void binds() {}

  /// List of imported modules that this module depends on.
  ///
  /// Allows modular composition by importing submodules.
  /// Defaults to an empty list.
  List<BinderRegistry> imports() => const [];
}
