// coverage:ignore-file

import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';

/// Extension on [BuildContext] to simplify access to dependencies managed
/// by the [GetIt] (GetIt).
///
/// This allows retrieving instances directly from the context without
/// needing to call `Modugo.i.get<T>()` or `GetIt.I.get<T>()` manually,
/// keeping your code cleaner and more readable.
///
/// ### Usage Example
/// ```dart
/// class HomePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // Retrieve a singleton or registered instance
///     final controller = context.read<HomeController>();
///
///     // Retrieve a specific instance by type or name
///     final primaryDb = context.read<Database>(type: Database, instanceName: 'primary');
///
///     return Scaffold(...);
///   }
/// }
/// ```
///
/// This is equivalent to:
/// ```dart
/// final controller = Modugo.i.get<HomeController>();
/// final primaryDb = Modugo.i.get<Database>(type: Database, instanceName: 'primary');
/// ```
///
/// ### Notes
/// - The optional [type] parameter allows specifying the exact type of the
///   dependency to retrieve when multiple instances of the same class exist.
/// - The optional [instanceName] can be used to fetch named instances
///   registered in the [GetIt].
extension ContextInjectionExtension on BuildContext {
  /// Retrieves a registered dependency of type [T] from the [GetIt].
  ///
  /// Parameters:
  /// - [type]: Optional. The exact type to retrieve when multiple types are registered.
  /// - [instanceName]: Optional. The name of the instance to fetch.
  ///
  /// Returns the instance of [T] from the [Injector].
  T read<T extends Object>({Type? type, String? instanceName}) =>
      GetIt.I.get<T>(type: type, instanceName: instanceName);
}
