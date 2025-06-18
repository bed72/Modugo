import 'package:flutter/foundation.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

@immutable
final class PathTokenModel implements IToken {
  /// A substring of the path specification.
  final String value;

  /// Creates a path token with [value].
  const PathTokenModel(this.value);

  @override
  String toPath(_) => value;

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
