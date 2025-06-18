import 'package:modugo/src/routes/paths/parse.dart';
import 'package:modugo/src/interfaces/token_interface.dart';

/// A function that generates a complete route path from a map of arguments.
///
/// Used to interpolate dynamic segments in route patterns,
/// such as `:id`, `:slug`, etc.
///
/// Example:
/// ```dart
/// final fn = pathToFunction('/product/:id');
/// final path = fn({'id': '42'}); // → '/product/42'
/// ```
typedef PathFunction = String Function(Map<String, String> args);

/// Creates a [PathFunction] from a route [path] specification.
///
/// The [path] may contain static and dynamic segments, such as:
/// - `/home`
/// - `/user/:id`
/// - `/search/:term/page/:page`
///
/// Internally, the path is parsed into tokens via [parse],
/// and converted into a function that interpolates arguments.
///
/// Example:
/// ```dart
/// final fn = pathToFunction('/user/:id');
/// final result = fn({'id': '123'}); // → '/user/123'
/// ```
PathFunction pathToFunction(String path) => tokensToFunction(parse(path));

/// Converts a list of parsed [IToken]s into a [PathFunction].
///
/// Each token is responsible for rendering its own portion of the path,
/// based on the provided arguments.
///
/// The resulting function will:
/// - concatenate all static and parameter tokens
/// - throw [ArgumentError] if a required parameter is missing or invalid
///
/// Example:
/// ```dart
/// final tokens = [PathTokenModel('user'), ParameterTokenModel('id')];
/// final fn = tokensToFunction(tokens);
/// final result = fn({'id': '5'}); // → 'user/5'
/// ```
PathFunction tokensToFunction(List<IToken> tokens) {
  return (args) {
    final buffer = StringBuffer();
    for (final token in tokens) {
      buffer.write(token.toPath(args));
    }

    return buffer.toString();
  };
}
