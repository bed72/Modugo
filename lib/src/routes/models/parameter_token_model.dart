import 'package:flutter/foundation.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

/// Corresponds to a parameter of a path specification.
@immutable
final class ParameterTokenModel implements IToken {
  /// The parameter name.
  final String name;

  /// The regular expression pattern this matches.
  final String pattern;

  /// The regular expression compiled from [pattern].
  late final regExp = RegExp('^$pattern\$');

  /// Creates a parameter token for [name].
  ParameterTokenModel(this.name, {this.pattern = r'([^/]+?)'});

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
