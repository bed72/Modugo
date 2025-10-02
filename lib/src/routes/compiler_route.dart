import 'package:modugo/src/routes/paths/parse.dart';
import 'package:modugo/src/routes/paths/regexp.dart';
import 'package:modugo/src/routes/paths/function.dart';
import 'package:modugo/src/routes/paths/extract.dart' as ex;

/// A compiled representation of a dynamic route path.
///
/// This class is responsible for transforming a human-friendly path pattern
/// into a set of reusable utilities for validation, matching, and building paths.
///
/// ### Responsibilities
/// - Parse the provided [pattern] into tokens (static and dynamic segments).
/// - Generate a [RegExp] that can match concrete URLs against the pattern.
/// - Extract parameter values from matching paths.
/// - Build concrete paths from parameter maps.
/// - Validate the pattern syntax to avoid malformed route definitions.
///
/// ### Supported parameter syntax
/// - Parameters start with `:` followed by a valid identifier:
///   - Valid: `:id`, `:slug`, `:userId`
///   - Invalid: `:(id`, `:1abc`, `::foo`, `:id-name`
///
/// ### Example
/// ```dart
/// final route = CompilerRoute('/product/:id');
///
/// route.match('/product/42');       // → true
/// route.extract('/product/42');     // → { 'id': '42' }
/// route.build({ 'id': '42' });      // → '/product/42'
/// route.parameters;                 // → ['id']
/// ```
final class CompilerRoute {
  /// The original path pattern used to define this route.
  ///
  /// Example: `/user/:id`
  final String pattern;

  /// Collected parameter names while parsing the pattern.
  final List<String> _parameters = [];

  /// Tokens parsed from the [pattern], including static and dynamic segments.
  late final _tokens = parse(pattern, parameters: _parameters);

  /// Regular expression generated from the [pattern], used to match incoming paths.
  late final _regExp = tokensToRegExp(_tokens);

  /// Function used to build a path string from a map of arguments.
  late final _builder = tokensToFunction(_tokens);

  /// Creates a [CompilerRoute] from a path [pattern].
  ///
  /// The constructor validates the syntax of the provided pattern to ensure
  /// parameters follow the expected format.
  CompilerRoute(this.pattern) {
    _validatePattern(pattern);
  }

  /// The [RegExp] used to match incoming paths against this route.
  RegExp get regExp => _regExp;

  /// Returns `true` if the given [path] matches this route's compiled [RegExp].
  ///
  /// Example:
  /// ```dart
  /// CompilerRoute('/user/:id').match('/user/123'); // → true
  /// ```
  bool match(String path) => _regExp.hasMatch(path);

  /// Builds a concrete path string by injecting [args] into the pattern.
  ///
  /// Throws an [ArgumentError] if a required parameter is missing or
  /// does not satisfy the expected format.
  ///
  /// Example:
  /// ```dart
  /// CompilerRoute('/user/:id').build({ 'id': '123' });
  /// // → '/user/123'
  /// ```
  String build(Map<String, String> args) => _builder(args);

  /// The list of parameter names defined in this route pattern.
  ///
  /// Example:
  /// ```dart
  /// CompilerRoute('/user/:id/:tab').parameters;
  /// // → ['id', 'tab']
  /// ```
  List<String> get parameters => List.unmodifiable(_parameters);

  /// Extracts path parameter values from a given [path], if it matches the pattern.
  ///
  /// Returns `null` if the path does not match.
  ///
  /// Example:
  /// ```dart
  /// CompilerRoute('/user/:id').extract('/user/123');
  /// // → { 'id': '123' }
  /// ```
  Map<String, String>? extract(String path) {
    // remove query params and fragment
    final cleanPath = path.split('?').first.split('#').first;

    final match = _regExp.matchAsPrefix(cleanPath);
    if (match == null) return null;
    return ex.extract(_parameters, match);
  }

  /// Validates the syntax of the route pattern.
  ///
  /// Ensures that:
  /// - Parameters begin with `:`
  /// - Parameter names follow the identifier rules:
  ///   `[a-zA-Z_][a-zA-Z0-9_]*`
  /// - No spaces are allowed within the path.
  ///
  /// Throws a [FormatException] if the pattern is malformed.
  void _validatePattern(String pattern) {
    final paramRegex = RegExp(r'^:[a-zA-Z_][a-zA-Z0-9_]*$');

    // Split by '/' to isolate each segment
    for (final segment in pattern.split('/')) {
      if (segment.startsWith(':')) {
        if (!paramRegex.hasMatch(segment)) {
          throw FormatException(
            'Invalid parameter syntax: $segment in "$pattern"',
          );
        }
      }
    }

    if (pattern.contains(' ')) {
      throw FormatException(
        'Invalid path syntax (contains spaces): "$pattern"',
      );
    }
  }
}
