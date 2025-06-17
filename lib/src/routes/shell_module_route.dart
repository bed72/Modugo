import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

@immutable
final class ShellModuleRoute implements IModule {
  final List<IModule> routes;
  final String? restorationScopeId;
  final List<NavigatorObserver>? observers;
  final List<void Function(IInjector)> binds;
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
    this.binds = const [],
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellModuleRoute &&
          runtimeType == other.runtimeType &&
          listEquals(routes, other.routes) &&
          listEquals(observers, other.observers) &&
          navigatorKey == other.navigatorKey &&
          restorationScopeId == other.restorationScopeId &&
          parentNavigatorKey == other.parentNavigatorKey;

  @override
  int get hashCode =>
      Object.hashAll(routes) ^
      Object.hashAll(observers ?? []) ^
      navigatorKey.hashCode ^
      restorationScopeId.hashCode ^
      parentNavigatorKey.hashCode;
}
