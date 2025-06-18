// coverage:ignore-file

/// Represents a token (segment or parameter) within a parsed route path.
///
/// This interface is used internally by the path compiler/parser in Modugo,
/// allowing different types of route tokens (e.g. static segments or dynamic parameters)
/// to be handled uniformly.
///
/// Implementations of this interface are responsible for:
/// - providing a regular expression pattern used for matching URLs ([toPattern])
/// - generating a concrete path string based on input parameters ([toPath])
///
/// Example use case:
/// - `/product/:id` would produce tokens like:
///   - StaticToken('product')
///   - ParamToken('id')
abstract interface class IToken {
  /// Returns a regular expression pattern that matches this token in a route.
  ///
  /// For example:
  /// - a static token like `'home'` returns `'home'`
  /// - a dynamic parameter like `':id'` returns `'([^/]+)'`
  String toPattern();

  /// Returns the concrete path string that corresponds to this token,
  /// using values from the [args] map.
  ///
  /// For example:
  /// ```dart
  /// final token = ParamToken('id');
  /// token.toPath({'id': '42'}); // → '42'
  /// ```
  ///
  /// If the required argument is missing from [args], the behavior depends
  /// on the implementation — it may throw, return an empty string, or fallback.
  String toPath(Map<String, String> args);
}
