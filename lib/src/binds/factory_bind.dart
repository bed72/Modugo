import 'dart:async';

import 'package:modugo/src/interfaces/injector_interface.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

/// Represents a factory binding in the [Injector].
///
/// A factory binding produces a **new instance** of a dependency **each time** it is requested.
///
/// Use cases for factory bindings include:
/// - Creating stateless objects that don't need to be shared.
/// - Producing disposable or short-lived objects.
/// - Providing instances that should not be reused globally or cached.
///
/// ### Behavior
/// Every call to `get` triggers the execution of the builder function, which
/// may be synchronous or asynchronous, producing a fresh instance.
///
/// ### Example
/// ```dart
/// injector.addFactory((injector) => LoginController());
///
/// // Each call returns a new LoginController instance:
/// final controller1 = await injector.get<LoginController>();
/// final controller2 = await injector.get<LoginController>();
/// assert(controller1 != controller2);
/// ```
///
/// ### Notes
/// - Since factory bindings produce new instances on demand, they usually
/// do not require disposal management by the injector.
/// - Disposal is a no-op and simply logs that no action was taken.
///
/// This class is intended for internal use by the [Injector].
final class FactoryBind<T> implements IBind<T> {
  /// The builder function that creates a new instance of [T].
  /// Can be synchronous or asynchronous.
  final FutureOr<T> Function(IInjector i) _builder;

  /// Creates a [FactoryBind] with the given builder function.
  FactoryBind(this._builder);

  /// Returns a new instance of [T] every time this method is called.
  /// Supports both synchronous and asynchronous builders.
  @override
  FutureOr<T> get(IInjector i) async {
    final result = _builder(i);
    return result is Future<T> ? await result : result;
  }

  /// Factory bindings typically do not require disposal because
  /// they produce fresh instances that are not cached.
  /// This method logs that no disposal action is performed.
  @override
  void dispose() {
    Logger.injection('dispose() called on FactoryBind, no action taken.');
  }
}
