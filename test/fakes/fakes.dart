import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

final class StateFake extends Fake implements GoRouterState {
  @override
  Uri get uri => Uri.parse('/home');
}

final class BuildContextFake extends Fake implements BuildContext {}
