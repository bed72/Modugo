import 'package:modugo/src/routes/paths/escape.dart';

import 'package:modugo/src/interfaces/token_interface.dart';

import 'package:modugo/src/routes/models/path_token_model.dart';
import 'package:modugo/src/routes/models/parameter_token_model.dart';

/// The default regular expression pattern used to match dynamic path parameters.
///
/// This pattern matches any non-slash (`/`) sequence lazily,
/// which is suitable for most path segments.
///
/// Example match:
/// - `42`
/// - `product-name`
/// - `abc123`
const _defaultPattern = '([^/]+?)';

/// Regular expression used to extract parameter tokens from a path specification.
///
/// It captures:
/// 1. The parameter name (e.g. `id` from `:id`)
/// 2. An optional custom regex pattern (e.g. `(\d+)` from `:id(\d+)`)
///
/// Example matches:
/// - `:id`
/// - `:slug([a-z\-]+)`
///
/// Group 1 → name
/// Group 2 → pattern (optional)
final _parameterRegExp = RegExp(
  /* (1) */ r':(\w+)'
  /* (2) */ r'(\((?:\\.|[^\\()])+\))?',
);

/// Parses a route [path] specification into a list of [IToken]s.
///
/// Supports both static segments (e.g. `/home`) and dynamic parameters (e.g. `:id`).
///
/// Parameters are identified and converted into:
/// - [PathTokenModel] for fixed segments
/// - [ParameterTokenModel] for dynamic segments
///
/// If [parameters] is provided, all parsed parameter names are added to it in order.
///
/// Example:
/// ```dart
/// final tokens = parse('/product/:id/:slug');
/// // tokens → [PathTokenModel('product/'), ParameterTokenModel('id'), ParameterTokenModel('slug')]
/// ```
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
