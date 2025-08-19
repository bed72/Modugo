extension UriPathWithExtras on Uri {
  /// Returns the full path including query and fragment if they exist.
  ///
  /// Examples:
  /// ```dart
  /// Uri.parse("https://example.com/page?foo=1#section").fullPath;
  /// // → /page?foo=1#section
  /// ```
  String get fullPath {
    final value = StringBuffer(path);
    if (query.isNotEmpty) value.write('?$query');
    if (fragment.isNotEmpty) value.write('#$fragment');
    return value.toString();
  }

  /// Returns true if this [Uri] contains the given [key] as a query parameter.
  bool hasQueryParam(String key) => queryParameters.containsKey(key);

  /// Returns the value for the given [key] from query parameters,
  /// or [defaultValue] if it does not exist.
  String? getQueryParam(String key, {String? defaultValue}) {
    return queryParameters[key] ?? defaultValue;
  }

  /// Returns true if this [Uri]'s path starts with [other]'s path.
  ///
  /// Useful to check if one route is a subpath of another.
  bool isSubPathOf(Uri other) => path.startsWith(other.path);

  /// Returns a new [Uri] with [subPath] appended to the current path.
  ///
  /// Ensures slashes are normalized.
  Uri withAppendedPath(String subPath) {
    final newPath = path.endsWith('/') ? '$path$subPath' : '$path/$subPath';
    return replace(path: newPath);
  }
}
