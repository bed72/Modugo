import 'package:get_it/get_it.dart';
import 'package:modugo/src/guard.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

/// A wrapper [Module] that injects a list of [IGuard]s recursively into all routes.
///
/// This allows applying guards defined at a parent module level to all nested routes
/// by wrapping the original module and overriding its `routes()` method.
///
/// It delegates binding and imports to the wrapped [_module].
final class GuardModel extends Module {
  final Module _module;
  final List<IGuard> _guards;

  GuardModel({required Module module, required List<IGuard> guards})
    : _guards = guards,
      _module = module;

  @override
  void binds() => _module.binds();

  @override
  bool get persistent => _module.persistent;

  @override
  List<Module> imports() => _module.imports();

  @override
  List<IModule> routes() =>
      propagateGuards(guards: _guards, routes: _module.routes());
}
