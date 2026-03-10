import 'package:flutter/widgets.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/logger.dart';

/// A widget that automatically calls [Module.dispose] when removed from
/// the widget tree.
///
/// Used internally by [FactoryRoute] when [ModuleRoute.disposeOnExit] is `true`.
/// Wraps the module's child widget and ties the module's lifecycle to
/// the widget's lifecycle.
///
/// When the user navigates away and this widget is unmounted,
/// [State.dispose] fires and calls [module.dispose()], which:
/// - Disposes all bindings registered by the module (in reverse order)
/// - Removes the module from the registry (allowing re-registration on return)
class ModuleDisposeScope extends StatefulWidget {
  final Module module;
  final Widget child;

  const ModuleDisposeScope({
    required this.module,
    required this.child,
    super.key,
  });

  @override
  State<ModuleDisposeScope> createState() => _ModuleDisposeScopeState();
}

class _ModuleDisposeScopeState extends State<ModuleDisposeScope> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    Logger.dispose(
      '${widget.module.runtimeType} auto-disposed (disposeOnExit)',
    );
    widget.module.dispose();
    super.dispose();
  }
}
