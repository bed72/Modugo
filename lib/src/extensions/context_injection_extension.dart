// coverage:ignore-file

import 'package:flutter/widgets.dart';

import 'package:modugo/src/modugo.dart';

/// Extension on [BuildContext] that provides a shorthand for retrieving
/// dependencies registered in the [ModugoContainer].
///
/// This extension allows any widget in the widget tree to access dependencies
/// directly from the [BuildContext], eliminating the need to manually call
/// `Modugo.container.get<T>()`.
///
///
/// ## Example
///
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
/// Equivalent to:
///
/// ```dart
/// final controller = Modugo.container.get<HomeController>();
/// ```
extension ContextInjectionExtension on BuildContext {
  /// Retrieves a registered dependency of type [T] from the [ModugoContainer].
  ///
  /// Throws [StateError] if no binding is found for [T].
  ///
  /// Example:
  /// ```dart
  /// final userService = context.read<UserService>();
  /// ```
  T read<T extends Object>() => Modugo.container.get<T>();

  /// Tries to retrieve a registered dependency of type [T].
  ///
  /// Returns `null` if no binding is found, instead of throwing.
  ///
  /// Example:
  /// ```dart
  /// final service = context.tryRead<MyService>() ?? fallbackService;
  /// ```
  T? tryRead<T extends Object>() => Modugo.container.tryGet<T>();
}
