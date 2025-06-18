/// Extracts path parameter values from a [match] and maps them to their corresponding [parameters].
///
/// This function is typically used after matching a path against a compiled [RegExp]
/// that was generated from a route pattern like `/product/:id`.
///
/// It assumes that the order of [parameters] corresponds exactly to the capturing groups
/// in the [RegExp], and it skips the full match group at index `0`.
///
/// Example:
/// ```dart
/// final parameters = ['id', 'slug'];
/// final match = RegExp(r'^/product/([^/]+)/([^/]+)$').firstMatch('/product/42/widget');
/// final result = extract(parameters, match!); // → { 'id': '42', 'slug': 'widget' }
/// ```
Map<String, String> extract(List<String> parameters, Match match) {
  final length = parameters.length;
  return {
    // Offset the group index by one since the first group is the entire match.
    for (int i = 0; i < length; ++i) parameters[i]: match.group(i + 1)!,
  };
}
