// coverage:ignore-file

import 'package:modugo/src/module.dart';

abstract interface class ManagerInterface {
  Module? get module;
  set module(Module? module);
  Map<Type, int> get bindReferences;
  bool isModuleActive(Module module);
  void unregisterBinds(Module module);
  void registerBindsIfNeeded(Module module);
  void registerBindsAppModule(Module module);

  void registerRoute(String route, Module module);
  void unregisterRoute(String route, Module module);
}
