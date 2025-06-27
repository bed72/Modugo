import 'package:flutter/widgets.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/routes/paths/function.dart';

/// Extension on [BuildContext] that provides convenient access to the current [GoRouterState].
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
/// final id = context.getPathParam('id');
/// final search = context.getStringQueryParam('q');
/// final isInitial = context.isInitialRoute;
/// final args = context.getExtra<MyModel>();
///
/// final uri = context.uri;
/// final routeName = context.name;
/// final fullPath = context.fullPath;
/// ```
extension ContextStateExtension on BuildContext {
  /// Retrieves the current [GoRouterState] associated with this [BuildContext].
  ///
  /// This provides access to:
  /// - current `path`, `uri`, `name`
  /// - route parameters and query parameters
  /// - any extra data passed during navigation
  ///
  /// Useful when you need to inspect the current route state inside a widget,
  /// such as reading parameters or checking which route is active.
  ///
  /// Example:
  /// ```dart
  /// final name = context.state.name;
  /// final id = context.state.pathParameters['id'];
  /// final tab = context.state.uri.queryParameters['tab'];
  /// ```
  GoRouterState get state => GoRouterState.of(this);

  /// Returns the [Uri] object representing the current route.
  ///
  /// Useful for extracting query parameters, fragments, and path segments
  /// from the active route within a widget context.
  Uri get uri => state.uri;

  /// The current matched route path.
  ///
  /// Example:
  /// ```dart
  /// if (context.path == '/home') {
  ///   // You're on the home screen
  /// }
  /// ```
  String get path => uri.path;

  /// Returns the name of the current route, if defined.
  ///
  /// This corresponds to the `name` property set in your route configuration.
  /// It can be used to identify or log the current route by its named reference.
  String? get name => state.name;

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
  /// final data = context.getExtra<MyData>();
  /// ```
  T? getExtra<T>() => state.extra as T?;

  /// Returns `true` if the current route has the given [name].
  ///
  /// Useful for checking if you're on a specific named route.
  ///
  /// Example:
  /// ```dart
  /// if (context.isCurrentRoute('dashboard')) {
  ///   // Show back button logic
  /// }
  /// ```
  bool isCurrentRoute(String name) => state.name == name;

  /// Returns `true` if the current matched route is the root (`'/'`).
  bool get isInitialRoute => state.matchedLocation == '/';

  /// Returns the segments of the current URI path as a list of strings.
  ///
  /// Example:
  /// ```dart
  /// // '/profile/settings' → ['profile', 'settings']
  /// final segments = context.locationSegments;
  /// ```
  List<String> get locationSegments => state.uri.pathSegments;

  /// Returns the value of a dynamic path parameter by its [param] name.
  ///
  /// Example:
  /// ```dart
  /// final userId = context.getPathParam('id'); // from '/user/:id'
  /// ```
  String? getPathParam(String param) => state.pathParameters[param];

  /// Returns the value of a query parameter as a string, if it exists.
  ///
  /// Example:
  /// ```dart
  /// final search = context.getStringQueryParam('q'); // from '?q=flutter'
  /// ```
  String? getStringQueryParam(String key) => state.uri.queryParameters[key];

  /// Returns the value of a query parameter as an integer, if parsable.
  ///
  /// Returns `null` if the parameter is missing or cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// final page = context.getIntQueryParam('page');
  /// ```
  int? getIntQueryParam(String key) =>
      int.tryParse(state.uri.queryParameters[key] ?? '');

  /// Builds a complete path string by applying [args] to a route [pattern].
  ///
  /// Example:
  /// ```dart
  /// final path = context.buildPath('/user/:id', {'id': '42'});
  /// // path → '/user/42'
  /// ```
  String buildPath(String pattern, Map<String, String> args) {
    final fn = pathToFunction(pattern);
    return fn(args);
  }

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
  /// final isActive = context.getBoolQueryParam('active');
  /// ```
  bool? getBoolQueryParam(String key) {
    final value = state.uri.queryParameters[key];
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Retrieves the `extra` data passed via navigation and **throws** if the type does not match.
  ///
  /// This is useful when the extra is required for rendering the current page
  /// and you want to fail early if it's missing or invalid.
  ///
  /// Example:
  /// ```dart
  /// final product = context.argumentsOrThrow<ProductModel>();
  /// ```
  ///
  /// Throws:
  /// - [Exception] if the `extra` is not of type [T].
  T argumentsOrThrow<T>() {
    final extra = state.extra;
    if (extra is T) return extra;
    throw Exception('Expected extra of type $T, got: $extra');
  }
}
