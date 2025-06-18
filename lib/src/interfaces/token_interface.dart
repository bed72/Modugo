// coverage:ignore-file

/// The base type of all tokens produced by a path specification.
abstract interface class IToken {
  /// Returns the regular expression pattern this matches.
  String toPattern();

  /// Returns the path representation of this given [args].
  String toPath(Map<String, String> args);
}
