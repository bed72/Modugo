import 'package:modugo/src/routes/paths/parse.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

/// Creates a [RegExp] that matches a route [path] specification.
///
/// Internally, this function:
/// 1. Parses the [path] into [IToken]s using [parse]
/// 2. Converts those tokens into a regex pattern using [tokensToRegExp]
///
/// Optional parameters:
/// - [parameters]: a list that will be filled with extracted parameter names (e.g. `:id`)
/// - [prefix]: if `true`, the regex will match only the beginning of a path
/// - [caseSensitive]: whether the match should be case-sensitive (default: `true`)
///
/// Example:
/// ```dart
/// final parameters = <String>[];
/// final regex = pathToRegExp('/user/:id', parameters: parameters);
///
/// final match = regex.firstMatch('/user/42');
/// final id = match?.group(1); // → '42'
/// ```
RegExp pathToRegExp(
  String path, {
  List<String>? parameters,
  bool prefix = false,
  bool caseSensitive = true,
}) => tokensToRegExp(
  parse(path, parameters: parameters),
  prefix: prefix,
  caseSensitive: caseSensitive,
);

/// Converts a list of [IToken]s into a [RegExp] that matches a full or partial route.
///
/// If [prefix] is `true`, the generated pattern matches only the beginning of the path.
/// Otherwise, it matches the entire string from start (`^`) to end (`$`).
///
/// - If [caseSensitive] is `false`, the resulting regex will ignore casing.
///
/// Special handling is applied if [prefix] is `true` and the last token
/// does **not** end with a `/`: a lookahead `(?=/|$)` is added to ensure
/// that the prefix does not match part of another segment.
///
/// Example:
/// ```dart
/// final tokens = parse('/shop/:id');
/// final regex = tokensToRegExp(tokens);
/// final match = regex.firstMatch('/shop/42');
/// ```
RegExp tokensToRegExp(
  List<IToken> tokens, {
  bool prefix = false,
  bool caseSensitive = true,
}) {
  final buffer = StringBuffer('^');
  String? lastPattern;

  for (final token in tokens) {
    lastPattern = token.toPattern();
    buffer.write(lastPattern);
  }

  if (!prefix) {
    buffer.write(r'$');
  } else if (lastPattern != null && !lastPattern.endsWith('/')) {
    // Match until a delimiter or end of input, unless:
    // - no tokens exist (i.e. empty path), or
    // - the last token ends with a slash
    buffer.write(r'(?=/|$)');
  }

  return RegExp(buffer.toString(), caseSensitive: caseSensitive);
}
