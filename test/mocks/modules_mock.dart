import 'package:flutter/material.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

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

final class ModuleWithRedirectMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ModuleRoute(
      '/',
      name: 'root',
      module: InnerModuleMock(),
      redirect: (_, __) => '/home',
    ),
  ];
}

final class ModuleWithShellMock extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModuleInterface> get routes => [
    ShellModuleRoute(
      binds: [Bind.singleton<ServiceMock>((_) => ServiceMock())],
      builder: (_, __, child) => Container(child: child),
      routes: [ChildRoute('tab1', child: (_, __) => const Placeholder())],
    ),
  ];
}

final class ModuleWithEmptyMock extends Module {
  @override
  List<ChildRoute> get routes => [
    ChildRoute('', name: 'empty', child: (_, __) => Container()),
  ];
}

final class ModuleWithDashMock extends Module {
  @override
  List<ChildRoute> get routes => [
    ChildRoute('/', name: 'root', child: (_, __) => const Placeholder()),
  ];
}

final class ModuleWithSettingsMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/', name: 'settings', child: (_, __) => const Placeholder()),
  ];
}

final class ModuleWithStatefulShellMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    StatefulShellModuleRoute(
      builder: (ctx, state, shell) => const Placeholder(),
      routes: [
        ModuleRoute('/', module: ModuleWithDashMock()),
        ModuleRoute('/settings', module: ModuleWithSettingsMock()),
      ],
    ),
  ];
}

final class ModuleWithBranchMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      'with-branch',
      name: 'with-branch-route',
      child: (_, __) => const Placeholder(),
    ),
  ];

  @override
  List<Bind> get binds => [Bind.singleton<ServiceMock>((_) => ServiceMock())];
}

final class ModuleWithExitMock extends Module {
  @override
  List<ModuleInterface> get routes => [
    ChildRoute(
      'exit',
      name: 'exit-route',
      onExit: (_, __) => true,
      child: (_, __) => const Placeholder(),
    ),
  ];

  @override
  List<Bind> get binds => [Bind.singleton<ServiceMock>((_) => ServiceMock())];
}
