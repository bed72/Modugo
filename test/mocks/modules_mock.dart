import 'package:flutter/material.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/injector.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import 'services_mock.dart';

final class InnerModuleMock extends Module {
  @override
  List<Bind<Object>> get binds => [Bind.factory((i) => CounterServiceMock())];
}

final class AnotherModuleMock extends Module {
  @override
  List<Bind<Object>> get binds => [];

  @override
  List<Module> get imports => [InnerModuleMock()];
}

final class RootModuleMock extends Module {
  @override
  List<Bind<Object>> get binds => [];

  @override
  List<Module> get imports => [InnerModuleMock()];
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
}
