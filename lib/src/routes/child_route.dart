import 'dart:async';

import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ChildRoute extends Equatable implements ModuleInterface {
  final String path;
  final String? name;
  final TypeTransition? transition;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final Widget Function(BuildContext context, GoRouterState state) child;
  final FutureOr<bool> Function(BuildContext context, GoRouterState state)?
  onExit;
  final Page<dynamic> Function(BuildContext context, GoRouterState state)?
  pageBuilder;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  const ChildRoute(
    this.path, {
    required this.child,
    this.name,
    this.onExit,
    this.redirect,
    this.transition,
    this.pageBuilder,
    this.parentNavigatorKey,
  });

  @override
  List<Object?> get props => [path, name, transition, parentNavigatorKey];
}
