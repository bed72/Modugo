import 'package:flutter/foundation.dart';

/// Represents a route pattern based on a regular expression.
///
/// This class is useful for validating whether a given path matches a route,
/// and for extracting path parameters from matched groups.
///
/// Example:
/// ```dart
/// final pattern = RoutePatternModel.from(r'^/user/(\w+)$', paramNames: ['id']);
/// final params = pattern.extractParams('/user/123'); // { 'id': '123' }
/// ```
@immutable
final class RoutePatternModel {
  /// The regular expression used to match the path.
  final RegExp regex;

  /// The list of parameter names in the order they appear in the regex groups.
  ///
  /// Example: `['id']` for `/user/:id`
  final List<String> paramNames;

  /// Creates an instance of [RoutePatternModel] with a precompiled [RegExp]
  /// and a list of named parameters.
  const RoutePatternModel(this.regex, this.paramNames);

  /// Creates an instance of [RoutePatternModel] from a [String] regex pattern
  /// and an optional list of [paramNames] matching the capture groups.
  ///
  /// The number and order of names in [paramNames] must match the regex groups.
  factory RoutePatternModel.from(
    String regexPattern, {
    List<String> paramNames = const [],
  }) {
    return RoutePatternModel(
      RegExp(regexPattern),
      List.unmodifiable(paramNames),
    );
  }

  /// Extracts parameters from a given [path] using the pattern.
  ///
  /// Returns a [Map] of matched parameter names to values.
  /// If the path does not match, returns an empty map.
  Map<String, String> extractParams(String path) {
    final match = regex.firstMatch(path);
    if (match == null) return {};

    final params = <String, String>{};
    for (int i = 0; i < paramNames.length; i++) {
      final value = match.group(i + 1);
      if (value != null) {
        params[paramNames[i]] = value;
      }
    }
    return params;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RoutePatternModel &&
            runtimeType == other.runtimeType &&
            regex.pattern == other.regex.pattern &&
            _listEquals(paramNames, other.paramNames);
  }

  @override
  int get hashCode => Object.hash(regex.pattern, Object.hashAll(paramNames));

  @override
  String toString() {
    return 'RoutePatternModel(regex: ${regex.pattern}, paramNames: $paramNames)';
  }

  /// Compares two lists of strings for equality by content and order.
  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
