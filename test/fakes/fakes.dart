import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

FutureOr<GoRouter> startModugoFake({
  required Module module,
  bool debugLogDiagnostics = false,
}) async => Modugo.configure(
  module: module,
  debugLogDiagnostics: debugLogDiagnostics,
  debugLogDiagnosticsGoRouter: debugLogDiagnostics,
);

final class StateFake extends Fake implements GoRouterState {
  @override
  Uri get uri => Uri.parse('/home');
}

final class BuildContextFake extends Fake implements BuildContext {}
