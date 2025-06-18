import 'package:modugo/src/routes/paths/escape.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

import 'package:modugo/src/routes/models/path_token_model.dart';
import 'package:modugo/src/routes/models/parameter_token_model.dart';

/// The default pattern used for matching parameters.
const _defaultPattern = '([^/]+?)';

/// The regular expression used to extract parameters from a path specification.
///
/// Capture groups:
///   1. The parameter name.
///   2. An optional pattern.
final _parameterRegExp = RegExp(
  /* (1) */ r':(\w+)'
  /* (2) */ r'(\((?:\\.|[^\\()])+\))?',
);

/// Parses a [path] specification.
///
/// Parameter names are added, in order, to [parameters] if provided.
List<IToken> parse(String path, {List<String>? parameters}) {
  int start = 0;
  final tokens = <IToken>[];
  final matches = _parameterRegExp.allMatches(path);

  for (final match in matches) {
    if (match.start > start) {
      tokens.add(PathTokenModel(path.substring(start, match.start)));
    }

    final name = match[1]!;
    final optionalPattern = match[2];
    final pattern =
        optionalPattern != null
            ? escapeGroup(optionalPattern)
            : _defaultPattern;
    tokens.add(ParameterTokenModel(name, pattern: pattern));
    parameters?.add(name);
    start = match.end;
  }

  if (start < path.length) {
    tokens.add(PathTokenModel(path.substring(start)));
  }

  return tokens;
}
