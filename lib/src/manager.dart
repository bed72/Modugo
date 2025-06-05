import 'dart:async';

import 'package:modugo/modugo.dart';
import 'package:modugo/src/logger.dart';

final class Manager implements ManagerInterface {
  Timer? _timer;
  Module? _module;
  List<Type> bindsToDispose = [];

  final Map<Type, int> _bindReferences = {};
  final Map<Module, Set<String>> _activeRoutes = {};

  static final Manager _instance = Manager._();

  Manager._();

  factory Manager() => _instance;

  @override
  Module? get module => _module;

  @override
  set module(Module? module) {
    _module = module;
  }

  @override
  Map<Type, int> get bindReferences => _bindReferences;

  @override
  bool isModuleActive(Module module) => _activeRoutes.containsKey(module);

  @override
  void registerBindsAppModule(Module module) {
    if (_module != null) return;

    _module = module;
    registerBindsIfNeeded(module);
  }

  @override
  void registerBindsIfNeeded(Module module) {
    if (_activeRoutes.containsKey(module)) return;

    _registerSyncBinds(module);

    _activeRoutes[module] = {};

    if (Modugo.debugLogDiagnostics) {
      _logImportedBinds(module);
      _logInjectionBinds(module);
    }
  }

  void _registerSyncBinds(Module module) {
    final allSyncBinds = <Bind>[
      ...module.binds,
      for (final imported in module.imports) ...imported.binds,
    ];
    _recursiveRegisterBinds(allSyncBinds);
  }

  @override
  void registerRoute(String route, Module module) {
    _activeRoutes.putIfAbsent(module, () => {});
    _activeRoutes[module]?.add(route);
  }

  @override
  void unregisterRoute(String route, Module module) {
    if (module == _module) return;

    _activeRoutes[module]?.remove(route);
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: disposeMilisenconds), () {
      if (_activeRoutes[module]?.isEmpty ?? true) unregisterBinds(module);

      _timer?.cancel();
    });
  }

  @override
  void unregisterBinds(Module module) {
    if (_module == module) return;
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (Modugo.debugLogDiagnostics) _logUnregisteredBinds(module);

    for (final bind in module.binds) {
      _decrementBindReference(_resolveBindType(bind));
    }

    for (final importedModule in module.imports) {
      for (final bind in importedModule.binds) {
        if (_module?.binds.contains(bind) ?? false) continue;
        _decrementBindReference(_resolveBindType(bind));
      }
    }

    bindsToDispose.map((type) => Bind.disposeByType(type)).toList();
    bindsToDispose.clear();

    _activeRoutes.remove(module);
  }

  Type _resolveBindType(Bind bind) =>
      bind.maybeInstance?.runtimeType ?? bind.runtimeType;

  void _recursiveRegisterBinds(List<Bind> binds, [int depth = 0]) {
    if (binds.isEmpty) return;

    final queueBinds = <Bind>[];

    for (final bind in binds) {
      try {
        _incrementBindReference(_resolveBindType(bind));

        if (ModugoLogger.enabled) {
          ModugoLogger.injection(
            'BIND: ${bind.type} | singleton: ${bind.isSingleton} | lazy: ${bind.isLazy}',
          );
        }

        Bind.register(bind);
      } catch (_) {
        queueBinds.add(bind);
      }
    }

    if (queueBinds.isEmpty) return;

    if (queueBinds.length == binds.length) {
      throw Exception(
        'Cyclic or unresolved dependencies: ${queueBinds.map((b) => _resolveBindType(b)).toList()}',
      );
    }

    _recursiveRegisterBinds(queueBinds, depth + 1);
  }

  void _incrementBindReference(Type type) {
    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
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

  void _logInjectionBinds(Module module) {
    final types = module.binds.map((b) => _resolveBindType(b)).toList();
    if (types.isEmpty) return;

    ModugoLogger.injection('🔗 Binds:');
    for (final type in types) {
      ModugoLogger.injection('    → $type');
    }
  }

  void _logImportedBinds(Module module) {
    final types =
        module.imports.expand((m) => m.binds).map(_resolveBindType).toList();
    if (types.isEmpty) return;

    ModugoLogger.info('📦 Imported Binds:');
    for (final type in types) {
      ModugoLogger.info('    → $type');
    }
  }

  void _logUnregisteredBinds(Module module) {
    final allTypes = [
      ...module.binds.map(_resolveBindType),
      ...module.imports.expand((m) => m.binds).map(_resolveBindType),
    ];
    if (allTypes.isEmpty) return;

    ModugoLogger.dispose('❌ Unregistering Binds from ${module.runtimeType}');
    for (final type in allTypes) {
      ModugoLogger.dispose('    → $type');
    }
  }
}
