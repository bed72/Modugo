// coverage:ignore-file

import 'package:flutter/material.dart';

/// A widget that waits for all asynchronous dependencies to be resolved
/// before building the main application widget.
///
/// You can pass a list of futures to [dependencies] that must complete
/// before the app UI is displayed. Typically, this includes
/// `GetIt.instance.allReady()` for async DI singletons.
///
/// Example usage:
/// ```dart
/// void main() {
///   runApp(
///     LoaderWidget(
///       dependencies: [GetIt.instance.allReady()],
///       loading: const CircularProgressIndicator(),
///       builder: (context) => const AppWidget(),
///     ),
///   );
/// }
/// ```
class ModugoLoaderWidget extends StatelessWidget {
  /// The widget displayed while waiting for dependencies to be ready.
  final Widget _loading;

  /// The list of futures that must complete before rendering the app.
  final Future<List<Future<void>>>? _dependencies;

  /// The builder function called when all dependencies are ready.
  final Widget Function(BuildContext) _builder;

  /// Creates a [ModugoLoaderWidget].
  ///
  /// [loading] is displayed while waiting.
  /// [builder] returns the main app widget once ready.
  /// [dependencies] is a list of async tasks to await before building.
  const ModugoLoaderWidget({
    super.key,
    required Widget loading,
    required Widget Function(BuildContext) builder,
    Future<List<Future<void>>>? dependencies,
  }) : _dependencies = dependencies,
       _loading = loading,
       _builder = builder;

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
