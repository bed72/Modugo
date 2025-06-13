import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ModuleRoute implements ModuleInterface {
  final String path;
  final String? name;
  final Module module;
  final String? Function(BuildContext, GoRouterState)? redirect;

  const ModuleRoute(
    this.path, {
    required this.module,
    this.name,
    this.redirect,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleRoute &&
          path == other.path &&
          name == other.name &&
          module == other.module &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => path.hashCode ^ name.hashCode ^ module.hashCode;
}
