// coverage:ignore-file

import 'package:go_router/go_router.dart';

/// Extension on [GoRouterState].
///
/// This extension exposes several properties and helpers to work with the
/// current navigation state, including:
/// - path and query parameters
/// - matched route name and location
/// - extras passed via navigation
/// - utilities to build paths dynamically
/// - access to the parsed [Uri] of the current route
/// - access to the original path pattern of the matched route
///
/// It's ideal for extracting route-related data directly within a widget,
/// without having to manually access [GoRouterState.of(context)].
///
/// Example:
/// ```dart
/// final id = state.getPathParam('id');
/// final search = state.getStringQueryParam('q');
/// final isInitial = state.isInitialRoute;
/// final args = state.getExtra<MyModel>();
///
/// final uri = state.uri;
/// final routeName = state.name;
/// final fullPath = state.fullPath;
/// ```
extension GoRouterStateExtension on GoRouterState {
  /// Returns the [Uri] object representing the current route.
  ///
  /// Useful for extracting query parameters, fragments, and path segments
  /// from the active route within a widget state.
  Uri get uri => this.uri;

  /// The current matched route path.
  ///
  /// Example:
  /// ```dart
  /// if (state.path == '/home') {
  ///   // You're on the home screen
  /// }
  /// ```
  String get path => uri.path;

  /// Returns the name of the current route, if defined.
  ///
  /// This corresponds to the `name` property set in your route configuration.
  /// It can be used to identify or log the current route by its named reference.
  String? get name => this.name;

  /// Returns the full navigated path, including query parameters.
  ///
  /// For example: `/test?query=value`
  String get fullPath => uri.toString();

  /// Retrieves the `extra` object passed during navigation, cast to type [T].
  ///
  /// Returns `null` if no `extra` is present or if the cast fails.
  ///
  /// Example:
  /// ```dart
  /// final data = state.getExtra<MyData>();
  /// ```
  T? getExtra<T>() => extra as T?;

  /// Returns `true` if the current route has the given [name].
  ///
  /// Useful for checking if you're on a specific named route.
  ///
  /// Example:
  /// ```dart
  /// if (state.isCurrentRoute('dashboard')) {
  ///   // Show back button logic
  /// }
  /// ```
  bool isCurrentRoute(String name) => name == name;

  /// Returns the path from the `extra` map if present, or falls back to [GoRouterState.uri.path].
  ///
  /// Useful for understanding the target destination in guards, redirects,
  /// or any navigation-based logic.
  ///
  /// Example:
  /// ```dart
  /// final path = state.effectivePath;
  /// if (path.startsWith('/cart')) { ... }
  /// ```
  String get effectivePath {
    final data = extra;
    if (data is Map<String, dynamic>) {
      final value = data['path'];
      if (value is String) return value;
    }
    return uri.path;
  }

  /// Returns `true` if the current matched route is the root (`'/'`).
  bool get isInitialRoute => matchedLocation == '/';

  /// Returns the segments of the current URI path as a list of strings.
  ///
  /// Example:
  /// ```dart
  /// // '/profile/settings' → ['profile', 'settings']
  /// final segments = state.locationSegments;
  /// ```
  List<String> get locationSegments => uri.pathSegments;

  /// Returns the value of a dynamic path parameter by its [param] name.
  ///
  /// Example:
  /// ```dart
  /// final userId = state.getPathParam('id'); // from '/user/:id'
  /// ```
  String? getPathParam(String param) => pathParameters[param];

  /// Returns the value of a query parameter as a string, if it exists.
  ///
  /// Example:
  /// ```dart
  /// final search = state.getStringQueryParam('q'); // from '?q=flutter'
  /// ```
  String? getStringQueryParam(String key) => uri.queryParameters[key];

  /// Returns the value of a query parameter as an integer, if parsable.
  ///
  /// Returns `null` if the parameter is missing or cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// final page = state.getIntQueryParam('page');
  /// ```
  int? getIntQueryParam(String key) =>
      int.tryParse(uri.queryParameters[key] ?? '');

  /// Returns the value of a query parameter as a boolean (`true` or `false`).
  ///
  /// Returns `null` if the key is missing.
  ///
  /// Accepted values (case-insensitive):
  /// - `'true'` → `true`
  /// - `'false'` → `false`
  ///
  /// Example:
  /// ```dart
  /// final isActive = state.getBoolQueryParam('active');
  /// ```
  bool? getBoolQueryParam(String key) {
    final data = uri.queryParameters[key];
    if (data == null) return null;
    return data.toLowerCase() == 'true';
  }

  /// Retrieves the `extra` data passed via navigation and **throws** if the type does not match.
  ///
  /// This is useful when the extra is required for rendering the current page
  /// and you want to fail early if it's missing or invalid.
  ///
  /// Example:
  /// ```dart
  /// final product = state.argumentsOrThrow<ProductModel>();
  /// ```
  ///
  /// Throws:
  /// - [Exception] if the `extra` is not of type [T].
  T argumentsOrThrow<T>() {
    final data = extra;
    if (data is T) return data;
    throw Exception('Expected extra of type $T, got: $data');
  }
}
