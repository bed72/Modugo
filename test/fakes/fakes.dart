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

final class BuildContextFake extends Fake implements BuildContext {}

final class StateFake extends Fake implements GoRouterState {
  @override
  Uri get uri => Uri.parse('/home');

  @override
  ValueKey<String> get pageKey => const ValueKey('fake-page');
}

final class StateWithParamsFake extends Fake implements GoRouterState {
  StateWithParamsFake({
    required String path,
    Map<String, String> params = const {},
  }) : _uri = Uri.parse(path),
       _params = params;

  final Uri _uri;
  final Map<String, String> _params;

  @override
  Uri get uri => _uri;

  @override
  Map<String, String> get pathParameters => _params;
}
