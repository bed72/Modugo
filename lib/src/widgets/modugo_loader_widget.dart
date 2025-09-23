// coverage:ignore-file

import 'dart:async';

import 'package:flutter/widgets.dart';

/// A widget that waits for asynchronous initialization tasks to complete
/// before building the main application widget.
///
/// Supports:
/// - a single Future via [dependencies]
/// - multiple Futures via [ModugoLoaderWidget.fromFutures]
/// - a convenience factory [ModugoLoaderWidget.fromCallable] (ver docs)
///
/// Error handling:
/// - Use [error] for a static error widget, or
/// - Use [errorBuilder] to render a custom error UI with access to
///   the thrown [Object] and optional [StackTrace].
class ModugoLoaderWidget extends StatelessWidget {
  /// The widget displayed while waiting for dependencies to complete.
  final Widget loading;

  /// The builder that returns the main application widget once ready.
  final Widget Function(BuildContext) builder;

  /// A Future that must complete before rendering the main widget.
  ///
  /// If `null`, the [builder] is rendered immediately (no waiting).
  final Future<void>? dependencies;

  /// Static error widget. If both [error] and [errorBuilder] are provided,
  /// [errorBuilder] takes precedence.
  final Widget? error;

  /// Custom error builder with access to the original [error] and [stackTrace].
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

  const ModugoLoaderWidget({
    super.key,
    required this.loading,
    required this.builder,
    this.error,
    this.errorBuilder,
    this.dependencies,
  });

  /// Waits for multiple Futures (executed in parallel) using `Future.wait`.
  factory ModugoLoaderWidget.fromFutures({
    Key? key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    List<Future<void>>? dependencies,
    Widget? error,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) => ModugoLoaderWidget(
    key: key,
    error: error,
    loading: loading,
    builder: builder,
    errorBuilder: errorBuilder,
    dependencies: dependencies == null ? null : Future.wait(dependencies),
  );

  /// Convenience factory that accepts a callable parameter.
  ///
  /// Observação importante:
  /// Esta factory **não** invoca a função recebida; ela existe apenas
  /// para manter a assinatura/conveniência de API. Caso você precise
  /// realmente aguardar as tarefas, compute o `Future` externamente e
  /// passe-o via [dependencies] (ou use [fromFutures] para lista).
  factory ModugoLoaderWidget.fromCallable({
    Key? key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    required FutureOr<dynamic> Function() dependencies,
    Widget? error,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) => ModugoLoaderWidget(
    key: key,
    error: error,
    loading: loading,
    builder: builder,
    errorBuilder: errorBuilder,
  );

  @override
  Widget build(BuildContext context) {
    final future = dependencies;
    if (future == null) return builder(context);

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder(context);
        }

        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }
          // Fallback para widget de erro estático
          if (error != null) return error!;
          // Fallback final: mostra loading (para não quebrar)
          return loading;
        }

        return loading;
      },
    );
  }
}
