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
///     return Scaffold(...);
///   }
/// }
/// ```
///
/// This is equivalent to:
/// ```dart
/// final controller = Injector().get<HomeController>();
/// ```
extension ContextInjectionExtension on BuildContext {
  /// Retrieves a registered dependency of type [T] from the [Injector].
  T read<T>() => Injector().get<T>();
}
