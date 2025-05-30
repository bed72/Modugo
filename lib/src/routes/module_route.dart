import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ModuleRoute extends Equatable implements ModuleInterface {
  final String path;
  final String? name;
  final Module module;

  const ModuleRoute(this.path, {required this.module, this.name});

  @override
  List<Object?> get props => [path, name, module];
}
