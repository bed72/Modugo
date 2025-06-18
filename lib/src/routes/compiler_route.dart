import 'package:modugo/src/routes/paths/parse.dart';
import 'package:modugo/src/routes/paths/regexp.dart';
import 'package:modugo/src/routes/paths/function.dart';
import 'package:modugo/src/routes/paths/extract.dart' as ex;

/// A compiled representation of a dynamic route path.
///
/// This class handles:
/// - parsing a path pattern into tokens
/// - generating a [RegExp] for matching
/// - extracting path parameters from URLs
/// - building URLs from parameter maps
///
/// It's useful for internal validation, parameter extraction, and dynamic path generation.
///
/// Example:
/// ```dart
/// final route = CompilerRoute('/product/:id');
///
/// route.match('/product/42'); // → true
/// route.extract('/product/42'); // → { 'id': '42' }
/// route.build({ 'id': '42' }); // → '/product/42'
/// ```
final class CompilerRoute {
  /// The original path pattern used to define this route.
  ///
  /// Example: `/user/:id`
  final String pattern;

  final List<String> _parameters = [];

  /// Tokens parsed from the [pattern], including static and dynamic segments.
  late final _tokens = parse(pattern, parameters: _parameters);

  /// Regular expression generated from the [pattern], used to match URLs.
  late final _regExp = tokensToRegExp(_tokens);

  /// Function used to build a path from a map of arguments.
  late final _builder = tokensToFunction(_tokens);

  /// Creates a [CompilerRoute] from a path [pattern].
  ///
  /// The [pattern] may include named parameters (e.g. `:id`) and
  /// optional inline regex patterns.
  CompilerRoute(this.pattern);

  /// Returns `true` if the given [path] matches this route's compiled [RegExp].
  bool match(String path) => _regExp.hasMatch(path);

  /// Extracts path parameter values from a given [path], if it matches the pattern.
  ///
  /// Returns `null` if no match is found.
  ///
  /// Example:
  /// ```dart
  /// route.extract('/user/123'); // → { 'id': '123' }
  /// ```
  Map<String, String>? extract(String path) {
    final match = _regExp.matchAsPrefix(path);
    if (match == null) return null;
    return ex.extract(_parameters, match);
  }

  /// Builds a path string by injecting [args] into the pattern.
  ///
  /// Throws an [ArgumentError] if a required argument is missing
  /// or if any value does not match the expected format.
  ///
  /// Example:
  /// ```dart
  /// route.build({ 'id': '42' }); // → '/product/42'
  /// ```
  String build(Map<String, String> args) => _builder(args);

  /// The [RegExp] used to match incoming paths.
  RegExp get regExp => _regExp;

  /// The list of parameter names expected by this route.
  ///
  /// This is populated during parsing.
  List<String> get parameters => List.unmodifiable(_parameters);
}
