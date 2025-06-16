import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ChildRoute implements ModuleInterface {
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

  factory ChildRoute.safeRootRoute() => ChildRoute(
    '/',
    name: 'safe-root-route',
    child: (_, __) => const SizedBox.shrink(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildRoute &&
          path == other.path &&
          name == other.name &&
          transition == other.transition &&
          runtimeType == other.runtimeType &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      transition.hashCode ^
      parentNavigatorKey.hashCode;
}
