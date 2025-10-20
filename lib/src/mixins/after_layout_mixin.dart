// coverage:ignore-file

import 'dart:async';

import 'package:flutter/widgets.dart';

/// A mixin that executes a callback **after the first frame has been rendered**.
///
/// This is useful when you need to safely call methods or access the
/// [BuildContext] only after the widget tree is fully built and laid out.
///
/// Typical use cases:
/// - Triggering an initial data load from a [Cubit], [ViewModel], [Notifier].
/// - Showing dialogs, snackbars, or navigating after the screen is ready.
/// - Starting animations or measurements that depend on the rendered layout.
///
/// ### Behavior
/// - Subscribes to [WidgetsBinding.endOfFrame] in [initState].
/// - Once the first frame completes, it calls [afterFirstLayout] if the widget is still mounted.
/// - Provides the widget's [BuildContext] as an argument for safe access.
///
/// ### Example
/// ```dart
/// class MyScreen extends StatefulWidget {
///   const MyScreen({super.key});
///
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with AfterLayoutMixin {
///   @override
///   Widget build(BuildContext context) {
///     return const Scaffold(body: Center(child: Text('Hello World')));
///   }
///
///   @override
///   Future<void> afterFirstLayout(BuildContext context) async {
///     // Safe to call ViewModel or Navigator here
///     debugPrint('Screen is fully built!');
///   }
/// }
/// ```
///
/// In this example, `afterFirstLayout` runs only once, immediately
/// after the widget has finished its first layout pass.
mixin AfterLayout<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) afterFirstLayout(context);
    });
  }

  /// Called once after the first layout is complete.
  ///
  /// Safe place to call navigation, show dialogs, or trigger initial data loading.
  FutureOr<void> afterFirstLayout(BuildContext context);
}
