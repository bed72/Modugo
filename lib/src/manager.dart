import 'dart:async';

import 'package:modugo/modugo.dart';
import 'package:modugo/src/logger.dart';
import 'package:modugo/src/routes/models/route_access_model.dart';

final class Manager implements IManager {
  Timer? _timer;
  Module? _module;

  final Map<Type, int> _bindReferences = {};
  final Map<Module, Set<Type>> _moduleTypes = {};
  final Map<Module, List<RouteAccessModel>> _activeRoutes = {};

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
  List<RouteAccessModel> getActiveRoutesFor(Module module) =>
      _activeRoutes[module]?.toList() ?? [];

  @override
  void registerBindsAppModule(Module module) {
    if (_module != null) return;

    _module = module;
    registerBindsIfNeeded(module);
  }

  @override
  void registerBindsIfNeeded(Module module) {
    if (_activeRoutes.containsKey(module)) return;

    _registerBinds(module);
    _activeRoutes[module] = [];

    if (Modugo.debugLogDiagnostics) {
      Logger.info('[MODULO]: ${module.runtimeType}');
    }
  }

  @override
  void registerRoute(String path, Module module, {String? branch}) {
    _activeRoutes.putIfAbsent(module, () => []);
    _activeRoutes[module]?.add(RouteAccessModel(path, branch));
  }

  @override
  void unregisterRoute(String path, Module module, {String? branch}) {
    if (module == _module) return;

    _activeRoutes[module]?.removeWhere(
      (r) => r.path == path && r.branch == branch,
    );

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

    if (Modugo.debugLogDiagnostics) {
      Logger.dispose('[UNREGISTERING] Binds from ${module.runtimeType}');
    }

    final types = _moduleTypes.remove(module) ?? {};

    for (final type in types) {
      _decrementBindReference(type);
    }

    _activeRoutes.remove(module);
  }

  void _registerBinds(Module module) {
    final allRegistrars = <void Function(IInjector)>[
      ...module.binds,
      for (final imported in module.imports) ...imported.binds,
    ];

    final typesForModule = <Type>{};

    for (final register in allRegistrars) {
      final before = Injector().registeredTypes;
      register(Injector());
      final after = Injector().registeredTypes;

      final newTypes = after.difference(before);
      for (final type in newTypes) {
        _incrementBindReference(type);
        typesForModule.add(type);

        if (Logger.enabled) Logger.injection('[BINDS]: $type');
      }
    }

    _moduleTypes[module] = typesForModule;
  }

  void _incrementBindReference(Type type) {
    _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
  }

  void _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);
        Injector().disposeByType(type);
      }
    }
  }
}
