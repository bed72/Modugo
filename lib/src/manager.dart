import 'dart:async';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';
import 'package:modugo/src/dispose.dart';
import 'package:modugo/src/injectors/sync_injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';
import 'package:modugo/src/interfaces/manager_interface.dart';

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
  Future<void> registerBindsAppModule(Module module) async {
    if (_module != null) return;

    _module = module;
    registerBindsIfNeeded(module);
  }

  @override
  Future<void> registerBindsIfNeeded(Module module) async {
    if (_activeRoutes.containsKey(module)) return;

    _registerSyncBinds(module);
    _registerAsyncBinds(module);

    _activeRoutes[module] = {};

    if (Modugo.debugLogDiagnostics) _logModuleBindsTypes(module);
  }

  void _registerSyncBinds(Module module) {
    final allSyncBinds = <SyncBind>[
      ...module.syncBinds,
      for (final imported in module.imports) ...imported.syncBinds,
    ];
    _recursiveRegisterBinds(allSyncBinds);
  }

  Future<void> _registerAsyncBinds(Module module) async {
    final allAsyncBinds = <AsyncBind>[
      ...module.asyncBinds,
      for (final imported in module.imports) ...imported.asyncBinds,
    ];

    if (ModugoLogger.enabled) {
      for (final bind in allAsyncBinds) {
        final deps = bind.dependsOn.map((d) => d.toString()).join(', ');
        ModugoLogger.injection(
          'ASYNC BIND: ${bind.type} | singleton: ${bind.isSingleton} | dependsOn: [$deps]',
        );
      }
    }

    await AsyncBind.registerAllWithDependencies(allAsyncBinds);

    if (ModugoLogger.enabled) {
      ModugoLogger.injection('✅ Async binds registered com sucesso.');
    }
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

    _timer = Timer(Duration(milliseconds: disposeMilisenconds), () async {
      if (_activeRoutes[module]?.isEmpty ?? true) {
        await unregisterBinds(module);
      }
      _timer?.cancel();
    });
  }

  @override
  Future<void> unregisterBinds(Module module) async {
    if (_module == module) return;
    if (_activeRoutes[module]?.isNotEmpty ?? false) return;

    if (Modugo.debugLogDiagnostics) _logModuleBindsTypes(module);

    for (final bind in module.syncBinds) {
      _decrementBindReference(_resolveBindType(bind));
    }

    for (final importedModule in module.imports) {
      for (final bind in importedModule.syncBinds) {
        if (_module?.syncBinds.contains(bind) ?? false) continue;
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
        if (_module?.asyncBinds.contains(asyncBind) ?? false) continue;
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

        if (ModugoLogger.enabled) {
          ModugoLogger.injection(
            'SYNC BIND: ${bind.type} | singleton: ${bind.isSingleton} | lazy: ${bind.isLazy}',
          );
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

  void _logModuleBindsTypes(Module module) {
    void logGroup(String title, Iterable<String> items) {
      if (items.isEmpty) return;
      ModugoLogger.injection('$title:');
      for (final item in items) {
        ModugoLogger.injection('    → $item');
      }
    }

    logGroup(
      '🔗 Sync Binds',
      module.syncBinds.map((b) => _resolveBindType(b).toString()),
    );

    logGroup(
      '📦 Imported Sync Binds',
      module.imports
          .expand((m) => m.syncBinds)
          .map((b) => _resolveBindType(b).toString()),
    );

    logGroup(
      '🌀 Async Binds',
      module.asyncBinds.map((b) => b.runtimeType.toString()),
    );

    logGroup(
      '📥 Imported Async Binds',
      module.imports
          .expand((m) => m.asyncBinds)
          .map((b) => b.runtimeType.toString()),
    );
  }
}
