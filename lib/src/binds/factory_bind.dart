import 'package:modugo/src/injector.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

/// A bind that creates a **new instance** of a dependency **every time** it is requested.
///
/// This is useful when you want **stateless**, **disposable** objects
/// or objects that should not be shared across different parts of the app.
///
/// Example:
/// ```dart
/// Bind.factory((i) => LoginController());
/// ```
///
/// In this case, every time `Injector.get<LoginController>()` is called,
/// a **new instance** of `LoginController` will be created.
///
/// This class is used internally when registering a `Bind.factory(...)`.
final class FactoryBind<T> implements IBind<T> {
  /// The function responsible for building a new instance of [T].
  final T Function(Injector i) _builder;

  /// Creates a new [FactoryBind] using the provided [_builder] function.
  FactoryBind(this._builder);

  /// Returns a **new instance** of [T] every time this method is called.
  @override
  T get(Injector i) => _builder(i);

  /// No disposal logic is needed for factory binds,
  /// but logs a message if [Modugo.debugLogDiagnostics] is enabled.
  @override
  void dispose() {
    ModugoLogger.injection('dispose() called, but no action taken.');
  }
}
