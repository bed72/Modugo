import 'package:modugo/src/module.dart';
import 'package:modugo/src/guard.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

/// A wrapper [Module] that injects a list of [IGuard]s recursively into all routes.
///
/// This allows applying guards defined at a parent module level to all nested routes
/// by wrapping the original module and overriding its `routes()` method.
///
/// It delegates binding and imports to the wrapped [_baseModule].
final class GuardModel extends Module {
  final Module _baseModule;
  final List<IGuard> _parentGuards;

  GuardModel(this._baseModule, this._parentGuards);

  @override
  List<IModule> routes() {
    final baseRoutes = _baseModule.routes();
    return propagateGuards(routes: baseRoutes, guards: _parentGuards);
  }

  @override
  void binds(IInjector i) => _baseModule.binds(i);

  @override
  List<Module> imports() => _baseModule.imports();

  @override
  bool get persistent => _baseModule.persistent;
}
