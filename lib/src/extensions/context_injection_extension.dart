// coverage:ignore-file

import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';

/// Extension on [BuildContext] that provides a shorthand for retrieving
/// dependencies registered in the global [GetIt] service locator.
///
/// This extension allows any widget in the widget tree to access dependencies
/// directly from the [BuildContext], eliminating the need to manually call
/// `Modugo.i.get<T>()` or `GetIt.I.get<T>()`.
///
/// It helps maintain cleaner, more readable widget trees by integrating
/// dependency injection seamlessly into the widget layer.
///
///
/// ## Example
///
/// ```dart
/// class HomePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // Retrieve a controller from the dependency container
///     final controller = context.read<HomeController>();
///
///     // Retrieve a specific instance by type or instance name
///     final primaryDb = context.read<Database>(
///       type: Database,
///       instanceName: 'primary',
///     );
///
///     return Scaffold(...);
///   }
/// }
/// ```
///
/// Equivalent to:
///
/// ```dart
/// final controller = Modugo.i.get<HomeController>();
/// final primaryDb = Modugo.i.get<Database>(
///   type: Database,
///   instanceName: 'primary',
/// );
/// ```
///
///
/// ## Parameters
/// - `param1`, `param2`: Optional parameters used when resolving factory
///   functions that accept arguments.
/// - `type`: The specific [Type] to resolve, useful when multiple
///   implementations of the same interface are registered.
/// - `instanceName`: The registration name of a dependency, when multiple
///   instances of the same type exist.
///
///
/// ## Returns
/// The resolved instance of type [T] from the global [GetIt] container.
///
///
/// ## Notes
/// - This method should only be used within a valid widget context.
/// - It mirrors the API of `GetIt.I.get<T>()`, maintaining full compatibility
///   with all Modugo dependency injection features.
extension ContextInjectionExtension on BuildContext {
  /// Retrieves a registered dependency of type [T] from the [GetIt] container.
  ///
  /// Provides optional parameters for resolving specific instances or
  /// parameterized factories.
  ///
  /// Example:
  /// ```dart
  /// final userService = context.read<UserService>();
  /// final repo = context.read<Repository>(instanceName: 'remote');
  /// ```
  ///
  /// Returns:
  /// The instance of type [T] as registered in [GetIt].
  T read<T extends Object>({
    dynamic param1,
    dynamic param2,
    Type? type,
    String? instanceName,
  }) => GetIt.I.get<T>(
    param1: param1,
    param2: param2,
    type: type,
    instanceName: instanceName,
  );
}
