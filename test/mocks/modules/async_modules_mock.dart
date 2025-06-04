import 'package:flutter/widgets.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/injectors/sync_injector.dart';
import 'package:modugo/src/injectors/async_injector.dart';
import 'package:modugo/src/interfaces/module_interface.dart';

import '../services_mock.dart';

final class ModuleWithSyncAndAsyncMock extends Module {
  @override
  List<SyncBind> get syncBinds => [
    SyncBind.factory<SyncServiceMock>((_) => SyncServiceMock()),
  ];

  @override
  List<AsyncBind> get asyncBinds => [
    AsyncBind<AsyncServiceMock>(
      (_) async => AsyncServiceMock(onClose: () {}),
      disposeAsync: (instance) async => instance.close(),
    ),
  ];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/home', child: (context, state) => const Placeholder()),
  ];
}

final class ModuleWithAsyncMock extends Module {
  @override
  List<AsyncBind> get asyncBinds => [
    AsyncBind<AsyncServiceMock>(
      (_) async => AsyncServiceMock(onClose: () {}),
      disposeAsync: (instance) async => instance.close(),
    ),
  ];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/home', child: (context, state) => const Placeholder()),
  ];
}
