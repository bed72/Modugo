import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ModuleRoute extends Equatable implements ModuleInterface {
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
  List<Object?> get props => [path, name, module];
}
