// coverage:ignore-file

import 'package:modugo/src/injector.dart';

/// Interface that defines the contract for all types of binds used in the Modugo dependency system.
///
/// Every bind must implement:
/// - how to **resolve** the instance (`get`)
/// - how to **clean up resources** if needed (`dispose`)
///
/// This interface is used internally by `Bind` types such as:
/// - [FactoryBind] — creates a new instance every time
/// - [SingletonBind] — creates and stores the instance immediately
/// - [LazySingletonBind] — creates the instance once on first access
///
/// Example of a custom implementation:
/// ```dart
/// class MyCustomBind<T> implements IBind<T> {
///   final T _instance;
///
///   MyCustomBind(this._instance);
///
///   @override
///   T get(Injector injector) => _instance;
///
///   @override
///   void dispose() {
///     // Optionally handle cleanup
///   }
/// }
/// ```
abstract interface class IBind<T> {
  /// Returns the instance of [T], possibly creating or reusing it.
  T get(Injector injector);

  /// Cleans up any held resources.
  ///
  /// Called automatically when the dependency is unregistered.
  void dispose();
}
