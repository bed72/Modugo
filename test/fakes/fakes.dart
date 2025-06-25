import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

FutureOr<GoRouter> startModugoFake({
  required Module module,
  bool debugLogDiagnostics = true,
}) async => Modugo.configure(
  module: module,
  delayDisposeMilliseconds: 600,
  debugLogDiagnostics: debugLogDiagnostics,
  debugLogDiagnosticsGoRouter: debugLogDiagnostics,
);

final class StateFake extends Fake implements GoRouterState {
  @override
  Uri get uri => Uri.parse('/home');
}

final class BuildContextFake extends Fake implements BuildContext {}
