// coverage:ignore-file

import 'dart:async';

import 'package:flutter/widgets.dart';

/// A widget that waits for asynchronous initialization tasks to complete
/// before building the main application widget.
///
/// Supports both a single [Future] and multiple [Future]s.
///
class ModugoLoaderWidget extends StatelessWidget {
  /// The widget displayed while waiting for dependencies to complete.
  final Widget _loading;

  /// The future that must complete before rendering the main widget.
  final Future<void>? _dependencies;

  /// The builder that returns the main application widget once ready.
  final Widget Function(BuildContext) _builder;

  /// Creates a [ModugoLoaderWidget] that waits for a single [Future].
  const ModugoLoaderWidget({
    super.key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    Future<void>? dependencies,
  }) : _loading = loading,
       _builder = builder,
       _dependencies = dependencies;

  /// Creates a [ModugoLoaderWidget] that waits for multiple [Future]s.
  factory ModugoLoaderWidget.fromFutures({
    Key? key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    List<Future<void>>? dependencies,
  }) => ModugoLoaderWidget(
    key: key,
    builder: builder,
    loading: loading,
    dependencies: dependencies == null ? null : Future.wait(dependencies),
  );

  /// Creates a [ModugoLoaderWidget] from a function returning either
  /// a `Future<void>` or a `List<Future<void>>`.
  factory ModugoLoaderWidget.fromCallable({
    Key? key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    required FutureOr<dynamic> Function() dependencies,
  }) {
    final result = dependencies();

    if (result is Future<void>) {
      return ModugoLoaderWidget(
        key: key,
        loading: loading,
        builder: builder,
        dependencies: result,
      );
    }

    if (result is List<Future<void>>) {
      return ModugoLoaderWidget(
        key: key,
        loading: loading,
        builder: builder,
        dependencies: Future.wait(result),
      );
    }

    throw ArgumentError(
      'dependencies must return either Future<void> or List<Future<void>>',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dependencies == null) {
      return _builder(context);
    }

    return FutureBuilder<void>(
      future: _dependencies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _builder(context);
        }

        if (snapshot.hasError) {
          return _loading;
        }

        return _loading;
      },
    );
  }
}
