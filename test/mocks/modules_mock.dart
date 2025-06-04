import 'package:flutter/material.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'services_mock.dart';

final class CyclicMock {
  final CyclicBMock b;
  CyclicMock(this.b);
}

final class CyclicBMock {
  final CyclicMock a;
  CyclicBMock(this.a);
}

final class CyclicModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.factory<CyclicMock>((i) => CyclicMock(i.get<CyclicBMock>())),
    Bind.factory<CyclicBMock>((i) => CyclicBMock(i.get<CyclicMock>())),
  ];
}

final class InnerModuleMock extends Module {
  @override
  List<Bind> get binds => [Bind.factory<ServiceMock>((i) => ServiceMock())];
}

final class AnotherModuleMock extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<Module> get imports => [InnerModuleMock()];
}

final class RootModuleMock extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<Module> get imports => [InnerModuleMock()];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      '/profile',
      name: 'profile-root',
      child: (context, state) => const Placeholder(),
    ),
  ];
}

final class OtherInnerModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/', child: (context, state) => const Placeholder()),
    ChildRoute('/settings', child: (context, state) => const Placeholder()),
  ];
}

final class OtherModuleMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/home', child: (context, state) => const Placeholder()),
    ModuleRoute('/profile', module: OtherInnerModuleMock()),
    ShellModuleRoute(
      builder: (context, state, child) => Scaffold(body: child),
      routes: [
        ChildRoute('/dashboard', child: (context, state) => Placeholder()),
      ],
    ),
  ];

  @override
  List<Bind> get binds => [Bind.factory<ServiceMock>((i) => ServiceMock())];
}

final class ShellModuleWithInvalidRouteMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ShellModuleRoute(
      builder: (_, __, child) => child,
      routes: [ChildRoute('/', child: (_, __) => const Placeholder())],
    ),
  ];
}

final class MultiModulesRootModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton<ModulesClientMock>((_) => ModulesClientMockImpl()),
    Bind.factory<ModulesRepositoryMock>(
      (i) => ModulesRepositoryMockImpl(client: i.get<ModulesClientMock>()),
    ),
  ];
}

final class MultiModulesInnerModuleMock extends Module {
  @override
  List<Module> get imports => [MultiModulesRootModuleMock()];

  @override
  List<Bind> get binds => [
    Bind.factory<ModulesCubitMock>(
      (i) => ModulesCubitMock(repository: i.get<ModulesRepositoryMock>()),
    ),
  ];
}

final class SingleModuleModuleMock extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton<ModulesClientMock>((_) => ModulesClientMockImpl()),
    Bind.factory<ModulesRepositoryMock>(
      (i) => ModulesRepositoryMockImpl(client: i.get<ModulesClientMock>()),
    ),
    Bind.factory<ModulesCubitMock>(
      (i) => ModulesCubitMock(repository: i.get<ModulesRepositoryMock>()),
    ),
  ];
}
