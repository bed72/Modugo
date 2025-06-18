String ensureLeadingSlash(String path) =>
    path.startsWith('/') ? path : '/$path';

bool hasEmbeddedParams(String routeName) => routeName.contains('/:');

String normalizePath(String path) {
  path = path.replaceAll(RegExp(r'/+'), '/');
  if (!path.endsWith('/')) path = '$path/';
  if (path == '/') return path;
  return path.substring(0, path.length - 1);
}

String removeDuplicatedPrefix(String module, String routeName) {
  if (routeName.startsWith(module)) {
    final stripped = routeName.substring(module.length);

    return stripped.startsWith('/') ? stripped.substring(1) : stripped;
  }

  return routeName;
}
