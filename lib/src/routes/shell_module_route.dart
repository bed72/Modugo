import 'dart:async';

import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/module_interface.dart';

@immutable
final class ShellModuleRoute extends Equatable implements ModuleInterface {
  final String? restorationScopeId;
  final List<ModuleInterface> routes;
  final List<NavigatorObserver>? observers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final FutureOr<String?> Function(BuildContext context, GoRouterState state)?
  redirect;

  final Widget Function(
    BuildContext context,
    GoRouterState state,
    Widget child,
  )?
  builder;
  final Page<dynamic> Function(
    BuildContext context,
    GoRouterState state,
    Widget child,
  )?
  pageBuilder;

  const ShellModuleRoute({
    required this.routes,
    required this.builder,
    this.redirect,
    this.observers,
    this.pageBuilder,
    this.navigatorKey,
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  @override
  List<Object?> get props => [
    routes,
    observers,
    navigatorKey,
    restorationScopeId,
    parentNavigatorKey,
  ];
}
