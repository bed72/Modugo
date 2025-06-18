/// Ensures that the given [path] starts with a leading slash (`/`).
///
/// If the path already starts with `/`, it is returned unchanged.
/// Otherwise, a `/` is prepended.
///
/// Example:
/// ```dart
/// ensureLeadingSlash('home');   // → '/home'
/// ensureLeadingSlash('/home');  // → '/home'
/// ```
String ensureLeadingSlash(String path) =>
    path.startsWith('/') ? path : '/$path';

/// Returns `true` if the given [routeName] contains inline parameters
/// defined within the string itself (e.g. `'/product/:id'`).
///
/// This is used to determine whether parameters are already part of
/// the route pattern and should not be appended manually.
///
/// Example:
/// ```dart
/// hasEmbeddedParams('/user/:id'); // → true
/// hasEmbeddedParams('/home');     // → false
/// ```
bool hasEmbeddedParams(String routeName) => routeName.contains('/:');

/// Normalizes a [path] by:
/// - collapsing repeated slashes (e.g. `//` → `/`)
/// - ensuring it ends with a single slash (except when root)
/// - removing the trailing slash for all non-root paths
///
/// Example:
/// ```dart
/// normalizePath('/shop///products'); // → '/shop/products'
/// normalizePath('/shop/products/');  // → '/shop/products'
/// ```
String normalizePath(String path) {
  path = path.replaceAll(RegExp(r'/+'), '/');
  if (!path.endsWith('/')) path = '$path/';
  if (path == '/') return path;
  return path.substring(0, path.length - 1);
}

/// Removes the duplicated [module] prefix from the beginning of [routeName], if present.
///
/// This avoids situations where a route like `'shop/shop/product'` is unintentionally built
/// due to combining module and route paths that both include the same prefix.
///
/// Example:
/// ```dart
/// removeDuplicatedPrefix('shop', 'shop/product'); // → 'product'
/// removeDuplicatedPrefix('shop', 'checkout');     // → 'checkout'
/// ```
String removeDuplicatedPrefix(String module, String routeName) {
  if (routeName.startsWith(module)) {
    final stripped = routeName.substring(module.length);
    return stripped.startsWith('/') ? stripped.substring(1) : stripped;
  }

  return routeName;
}
