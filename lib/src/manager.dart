import 'dart:async';
import 'dart:developer';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/injectors/sync_injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';
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

    final allAsyncBinds = <AsyncBind>[
      ...module.asyncBinds,
      for (final imported in module.imports) ...imported.asyncBinds,
    ];
    for (final asyncBind in allAsyncBinds) {
      AsyncBind.register(asyncBind);

      if (Modugo.debugLogDiagnostics) {
        log('REGISTERING ASYNC BIND: ${asyncBind.type}', name: '💉');
      }
    }

    final allSyncBinds = <SyncBind>[
      ...module.syncBinds,
      for (final imported in module.imports) ...imported.syncBinds,
    ];
    _recursiveRegisterBinds(allSyncBinds);

    _activeRoutes[module] = {};

    if (Modugo.debugLogDiagnostics) {
      log(
        'INJECTED: ${module.runtimeType} BINDS: ${_logModuleBindsTypes(module)}',
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

    _timer = Timer(Duration(milliseconds: disposeMilisenconds), () async {
      if (_activeRoutes[module]?.isEmpty ?? true) {
        await unregisterBinds(module);
      }
      _timer?.cancel();
    });
  }

  @override
  Future<void> unregisterBinds(Module module) async {
    if (_appModule == module) return;
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (Modugo.debugLogDiagnostics) {
      log(
        'DISPOSED: ${module.runtimeType} BINDS: ${_logModuleBindsTypes(module)}',
        name: '🗑️',
      );
    }

    // Dispose sync binds
    for (final bind in module.syncBinds) {
      _decrementBindReference(_resolveBindType(bind));
    }

    for (final importedModule in module.imports) {
      for (final bind in importedModule.syncBinds) {
        if (_appModule?.syncBinds.contains(bind) ?? false) continue;
        _decrementBindReference(_resolveBindType(bind));
      }
    }

    bindsToDispose.map((type) => SyncBind.disposeByType(type)).toList();
    bindsToDispose.clear();

    for (final asyncBind in module.asyncBinds) {
      await AsyncBind.disposeByType(asyncBind.runtimeType);
    }

    for (final imported in module.imports) {
      for (final asyncBind in imported.asyncBinds) {
        if (_appModule?.asyncBinds.contains(asyncBind) ?? false) continue;
        await AsyncBind.disposeByType(asyncBind.runtimeType);
      }
    }

    _activeRoutes.remove(module);
  }

  Type _resolveBindType(SyncBind bind) =>
      bind.maybeInstance?.runtimeType ?? bind.runtimeType;

  void _recursiveRegisterBinds(List<SyncBind> binds, [int depth = 0]) {
    if (binds.isEmpty) return;

    final queueBinds = <SyncBind>[];

    for (final bind in binds) {
      try {
        _incrementBindReference(_resolveBindType(bind));

        if (Modugo.debugLogDiagnostics) {
          log('REGISTERING SYNC BIND: ${bind.type}', name: '💉');
        }

        SyncBind.register(bind);
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

  String _logModuleBindsTypes(Module module) {
    final types = <String>[
      ...module.syncBinds.map((b) => _resolveBindType(b).toString()),
      for (final m in module.imports)
        ...m.syncBinds.map((b) => _resolveBindType(b).toString()),
      ...module.asyncBinds.map((b) => b.runtimeType.toString()),
      for (final m in module.imports)
        ...m.asyncBinds.map((b) => b.runtimeType.toString()),
    ];
    return types.toString();
  }
}
