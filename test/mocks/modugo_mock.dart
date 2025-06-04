import 'dart:async';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

FutureOr<GoRouter> startModugoMock({
  required Module module,
  bool debugLogDiagnostics = false,
}) async =>
    Modugo.configure(module: module, debugLogDiagnostics: debugLogDiagnostics);
