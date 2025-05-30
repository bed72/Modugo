import 'dart:async';
import 'dart:developer';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

final class Manager implements ManagerInterface {
  Timer? _timer;
  Module? _appModule;
  List<Type> bindsToDispose = [];

  final Map<Type, int> _bindReferences = {};
  final Map<Module, Set<String>> _activeRoutes = {};

  static final Manager _instance = Manager._();

  Manager._();

  factory Manager() => _instance;

  @override
  Map<Type, int> get bindReferences => _bindReferences;

  @override
  bool isModuleActive(Module module) => _activeRoutes.containsKey(module);

  @override
  void registerBindsAppModule(Module module) {
    if (_appModule != null) return;

    _appModule = module;
    registerBindsIfNeeded(module);
  }

  @override
  void registerBindsIfNeeded(Module module) {
    if (_activeRoutes.containsKey(module)) return;

    List<Bind<Object>> allBinds = [
      ...module.binds,
      ...module.imports.map((e) => e.binds).expand((e) => e),
    ];
    _recursiveRegisterBinds(allBinds);

    _activeRoutes[module] = {};

    if (Modugo.debugLogDiagnostics) {
      log(
        'INJECTED: ${module.runtimeType} BINDS: ${[...module.binds.map((e) => e.instance.runtimeType.toString()), ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())]}',
        name: '💉',
      );
    }
  }

  @override
  void registerRoute(String route, Module module) {
    _activeRoutes.putIfAbsent(module, () => {});
    _activeRoutes[module]?.add(route);
  }

  @override
  void unregisterRoute(String route, Module module) {
    if (module == _appModule) return;

    _activeRoutes[module]?.remove(route);
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: disposeMilisenconds), () {
      if (_activeRoutes[module] != null && _activeRoutes[module]!.isEmpty) {
        unregisterBinds(module);
      }
      _timer?.cancel();
    });
  }

  @override
  void unregisterBinds(Module module) {
    if (_appModule != null && module == _appModule!) return;

    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (Modugo.debugLogDiagnostics) {
      log(
        'DISPOSED: ${module.runtimeType} BINDS: ${[...module.binds.map((e) => e.instance.runtimeType.toString()), ...module.imports.map((e) => e.binds.map((e) => e.instance.runtimeType.toString()).toList())]}',
        name: '🗑️',
      );
    }

    for (final bind in module.binds) {
      _decrementBindReference(bind.instance.runtimeType);
    }

    if (module.imports.isNotEmpty) {
      for (final importedModule in module.imports) {
        for (final bind in importedModule.binds) {
          if (_appModule?.binds.contains(bind) ?? false) continue;
          _decrementBindReference(bind.instance.runtimeType);
        }
      }
    }

    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
    bindsToDispose.clear();

    _activeRoutes.remove(module);
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds) {
    if (binds.isEmpty) return;

    List<Bind<Object>> queueBinds = [];

    for (final bind in binds) {
      try {
        _incrementBindReference(bind.instance.runtimeType);
        Bind.register(bind);
      } catch (_) {
        queueBinds.add(bind);
      }
    }

    if (queueBinds.length < binds.length) {
      _recursiveRegisterBinds(queueBinds);
    }

    if (queueBinds.isNotEmpty) {
      for (final bind in queueBinds) {
        _incrementBindReference(bind.instance.runtimeType);
        Bind.register(bind);
      }
    }
  }

  void _incrementBindReference(Type type) {
    _bindReferences.containsKey(type)
        ? _bindReferences[type] = (_bindReferences[type] ?? 0) + 1
        : _bindReferences[type] = 1;
  }

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        bindsToDispose.add(type);
      }
    }
  }
}
