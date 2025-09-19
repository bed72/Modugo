// coverage:ignore-file

import 'package:flutter/foundation.dart';

import 'package:modugo/src/guard.dart';
import 'package:modugo/src/interfaces/binder_interface.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

/// A wrapper [Module] that injects a list of [IGuard]s recursively into all routes.
///
/// This allows applying guards defined at a parent module level to all nested routes
/// by wrapping the original module and overriding its `routes()` method.
///
/// It delegates binding and imports to the wrapped [_module].
@immutable
final class GuardModuleDecorator extends Module {
  final Module _module;
  final List<IGuard> _guards;

  List<IGuard> get guards => _guards;

  GuardModuleDecorator({required Module module, required List<IGuard> guards})
    : _guards = guards,
      _module = module;

  @override
  void binds() => _module.binds();

  @override
  List<IBinder> imports() => _module.imports();

  @override
  List<IRoute> routes() =>
      propagateGuards(guards: _guards, routes: _module.routes());

  /// Overrides [runtimeType] returning the decorated [Module.runtimeType]
  /// This allows us to execute [Module.binds] for each decorated [Module]
  @override
  Type get runtimeType => _module.runtimeType;
}
