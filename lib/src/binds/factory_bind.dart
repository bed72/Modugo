import 'package:modugo/src/interfaces/injector_interface.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

/// Internal class representing a factory binding in the [Injector].
///
/// This binding creates a **new instance** of a dependency **every time** it is requested.
///
/// Use cases:
/// - Stateless objects
/// - Disposable objects
/// - Objects that must not be shared globally
///
/// Example usage within the [Injector]:
/// ```dart
/// injector.addFactory((i) => LoginController());
/// ```
///
/// Each call to `Modugo.get<LoginController>()` will create a **new instance**
/// via this factory.
///
/// This class is used internally by the [Injector] when registering factory binds.
final class FactoryBind<T> implements IBind<T> {
  /// The function responsible for building a new instance of [T].
  final T Function(IInjector i) _builder;

  /// Creates a new [FactoryBind] using the provided [_builder] function.
  FactoryBind(this._builder);

  /// Returns a **new instance** of [T] every time this method is called.
  @override
  T get(IInjector i) => _builder(i);

  /// No disposal logic is needed for factory binds,
  /// but logs a message if [Modugo.debugLogDiagnostics] is enabled.
  @override
  void dispose() {
    Logger.injection('dispose() called, but no action taken.');
  }
}
