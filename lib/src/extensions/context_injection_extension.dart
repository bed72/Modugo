import 'package:flutter/widgets.dart';

import 'package:modugo/src/injector.dart';

/// Extension on [BuildContext] to access dependencies registered in the [Injector].
///
/// This provides a shorthand for retrieving dependencies using the current
/// application context, making the code cleaner and easier to read.
///
/// Example:
/// ```dart
/// class HomePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final controller = context.read<HomeController>();
///     final primaryDb = context.read<Database>(key: 'primary');
///     return Scaffold(...);
///   }
/// }
/// ```
///
/// This is equivalent to:
/// ```dart
/// final controller = Injector().get<HomeController>();
/// final primaryDb = Injector().get<Database>(key: 'primary');
/// ```
extension ContextInjectionExtension on BuildContext {
  /// Retrieves a registered dependency of type [T] from the [Injector].
  /// 
  /// Optionally specify a [key] to retrieve a specific instance when multiple
  /// instances of the same type are registered.
  T read<T>({String? key}) => Injector().get<T>(key: key);
}
