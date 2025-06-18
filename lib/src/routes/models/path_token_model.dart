import 'package:flutter/foundation.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

/// A token representing a **static segment** in a route path specification.
///
/// Used internally by the path parser, this token matches fixed, literal
/// segments of a route, such as `'home'`, `'settings'`, or `'cart'`.
///
/// Unlike [ParameterTokenModel], this token does **not** perform any validation
/// or substitution — it's a direct match.
///
/// Example:
/// ```dart
/// final token = PathTokenModel('home');
/// final pattern = token.toPattern(); // → 'home'
/// final path = token.toPath({});     // → 'home'
/// ```
@immutable
final class PathTokenModel implements IToken {
  /// The literal value of the static segment.
  final String value;

  /// Creates a static path token with a given [value].
  ///
  /// This should be a fixed string representing a part of the route.
  const PathTokenModel(this.value);

  /// Returns the static value directly, ignoring any input [args].
  ///
  /// Since this token is static, it does not rely on dynamic values.
  @override
  String toPath(_) => value;

  /// Escapes the [value] into a valid regular expression pattern.
  ///
  /// This ensures that characters like `/`, `.`, etc. are matched literally.
  @override
  String toPattern() => RegExp.escape(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathTokenModel &&
          value == other.value &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => value.hashCode;
}
