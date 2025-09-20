// coverage:ignore-file

import 'package:flutter/material.dart';

/// A widget that waits for asynchronous initialization tasks to complete
/// before building the main application widget.
///
/// This is typically used to delay the rendering of the app until
/// all required dependencies are ready (for example,
/// `GetIt.instance.allReady()` or a database initialization).
///
/// ### Usage
///
/// - **Single future:**
/// ```dart
/// void main() {
///   runApp(
///     ModugoLoaderWidget(
///       dependencies: GetIt.instance.allReady(),
///       loading: const CircularProgressIndicator(),
///       builder: (context) => const AppWidget(),
///     ),
///   );
/// }
/// ```
///
/// - **Multiple futures (wait for all):**
/// ```dart
/// void main() {
///   runApp(
///     ModugoLoaderWidget.fromFutures(
///       dependencies: [
///         GetIt.instance.allReady(),
///         initDatabase(),
///       ],
///       loading: const CircularProgressIndicator(),
///       builder: (context) => const AppWidget(),
///     ),
///   );
/// }
/// ```
///
/// In both cases, [loading] is displayed while waiting for the tasks,
/// and [builder] is called once all dependencies have completed.
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
  ///
  /// Internally calls `Future.wait` so that the app is only built
  /// once all tasks in [dependencies] have completed.
  factory ModugoLoaderWidget.fromFutures({
    Key? key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    List<Future<void>>? dependencies,
  }) {
    return ModugoLoaderWidget(
      key: key,
      builder: builder,
      loading: loading,
      dependencies: dependencies != null ? Future.wait(dependencies) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dependencies,
      builder:
          (context, snapshot) =>
              snapshot.connectionState != ConnectionState.done
                  ? _loading
                  : _builder(context),
    );
  }
}
