// coverage:ignore-file

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:modugo/src/injector.dart';

extension BindContextExtension on BuildContext {
  T read<T>() => Bind.get<T>();

  String? getPathParam(String param) =>
      GoRouterState.of(this).pathParameters[param];

  String? get path => GoRouterState.of(this).path;

  GoRouterState get state => GoRouterState.of(this);

  bool canPop() => GoRouter.of(this).canPop();

  void go(String location, {Object? extra}) =>
      GoRouter.of(this).go(location, extra: extra);

  void pop<T extends Object?>([T? result]) => GoRouter.of(this).pop(result);

  void replace(String location, {Object? extra}) =>
      GoRouter.of(this).replace<Object?>(location, extra: extra);

  void pushReplacement(String location, {Object? extra}) =>
      GoRouter.of(this).pushReplacement(location, extra: extra);

  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).replaceNamed<Object?>(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).pushNamed<T>(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  void pushReplacementNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).pushReplacementNamed(
    name,
    extra: extra,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  void goNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) => GoRouter.of(this).goNamed(
    name,
    extra: extra,
    fragment: fragment,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );
}
