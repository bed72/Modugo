import 'package:flutter/foundation.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

/// A token representing a **dynamic parameter** in a route path specification.
///
/// Used internally by Modugo's path parser and compiler, this token corresponds
/// to placeholders in routes like `:id`, `:slug`, or custom patterns like `:id(\d+)`.
///
/// It supports:
/// - extracting the parameter name
/// - validating values against a regex pattern
/// - generating the path string from a set of provided arguments
///
/// Example:
/// ```dart
/// final token = ParameterTokenModel('id');
/// final path = token.toPath({'id': '42'}); // → '42'
/// final regex = token.toPattern();         // → '([^/]+?)'
/// ```
///
/// Throws:
/// - [ArgumentError] if the required key is missing in [args]
/// - [ArgumentError] if the value does not match the declared pattern
@immutable
final class ParameterTokenModel implements IToken {
  /// The name of the parameter (e.g., `'id'` in `':id'`).
  final String name;

  /// The regular expression pattern that this parameter must match.
  ///
  /// Defaults to a permissive pattern: `([^/]+?)`, which matches any non-slash segment.
  final String pattern;

  /// A compiled [RegExp] based on [pattern], anchored to the full string.
  late final regExp = RegExp('^$pattern\$');

  /// Creates a parameter token with a [name] and optional [pattern].
  ///
  /// If no [pattern] is provided, defaults to a standard non-slash matcher.
  ParameterTokenModel(this.name, {this.pattern = r'([^/]+?)'});

  /// Returns the value from [args] corresponding to this parameter's [name].
  ///
  /// The value is validated against the [pattern].
  ///
  /// Throws:
  /// - [ArgumentError] if the [name] is missing in [args]
  /// - [ArgumentError] if the value does not match the [pattern]
  @override
  String toPath(Map<String, String> args) {
    final value = args[name];
    if (value != null) {
      if (!regExp.hasMatch(value)) {
        throw ArgumentError.value(
          '$args',
          'args',
          'Expected "$name" to match "$pattern", but got "$value"',
        );
      }
      return value;
    } else {
      throw ArgumentError.value('$args', 'args', 'Expected key "$name"');
    }
  }

  /// Returns the regular expression string used to match this parameter.
  ///
  /// This is used during route matching.
  @override
  String toPattern() => pattern;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterTokenModel &&
          name == other.name &&
          pattern == other.pattern &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => Object.hash(name, pattern);
}
