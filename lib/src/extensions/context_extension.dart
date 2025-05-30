import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:modugo/src/injector.dart';

extension BindContextExtension on BuildContext {
  T read<T>() {
    final bind = Bind.get<T>();
    return bind;
  }

  String? getPathParam(String param) =>
      GoRouterState.of(this).pathParameters[param];

  String? get path => GoRouterState.of(this).path;

  GoRouterState get state => GoRouterState.of(this);
}
