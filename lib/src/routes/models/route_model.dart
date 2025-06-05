import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:modugo/src/transitions/transition.dart';

@immutable
final class RouteModuleModel extends Equatable {
  final String name;
  final String route;
  final String child;
  final String module;
  final List<String>? params;
  final TypeTransition transition;

  const RouteModuleModel({
    required this.route,
    required this.child,
    required this.module,
    this.params,
    this.name = '',
    this.transition = TypeTransition.fade,
  });

  @override
  String toString() =>
      'RouteModuleModel(module: $module, child: $child, route: $route, params: $params)';

  @override
  List<Object?> get props => [name, route, child, module, params, transition];

  String buildPath({
    List<String> params = const [],
    List<String> subParams = const [],
  }) {
    String paramPath = params.map((e) => '/$e').join('');
    String subParamPath = subParams.map((e) => '/$e').join('');
    int indexChildR = child.contains('/:') ? child.indexOf('/:') : child.length;

    return _buildPath(
      module + subParamPath + child.substring(0, indexChildR) + paramPath,
    );
  }

  static RouteModuleModel build({
    required String module,
    required String routeName,
    List<String> params = const [],
  }) {
    final module_ = '/$module';
    final args_ = params.map((e) => ':$e').join('/');
    final sanitizedRouteName = routeName.replaceAll(RegExp(r'/+$'), '');
    final childRoute =
        '/${sanitizedRouteName == module ? '' : '$sanitizedRouteName/'}';

    return RouteModuleModel(
      params: params,
      child: _buildPath(childRoute + args_),
      name: _extractName(sanitizedRouteName),
      module: _buildPath('$module_${module == '/' ? '' : '/'}'),
      route: _buildPath(
        '$module_${sanitizedRouteName == module ? '/' : childRoute}',
      ),
    );
  }

  static String _extractName(String path) {
    final regex = RegExp(r'^/([^/]+)/?');
    final match = regex.firstMatch(path);

    return match != null && match.groupCount >= 1 ? match.group(1)! : path;
  }

  static String _buildPath(String path) {
    if (!path.endsWith('/')) path = '$path/';

    path = path.replaceAll(RegExp(r'/+'), '/');

    if (path == '/') return path;

    return path.substring(0, path.length - 1);
  }
}
