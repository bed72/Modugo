// coverage:ignore-file

import 'package:modugo/src/binding_key.dart';

/// Interface that defines the core contract for a dependency injector.
///
/// This interface powers Modugo's dependency system, allowing types to be:
/// - registered using different lifecycles (factory, singleton, lazy)
/// - retrieved generically via [get]
/// - disposed manually when needed
///
/// Typical usage is internal, but custom implementations or extensions can
/// conform to this interface.
///
/// Example:
/// ```dart
/// final injector = Injector();
///
/// injector
///   .addSingleton((i) => Logger())
///   .addFactory((i) => AuthController());
///
/// final controller = injector.get<AuthController>();
/// ```
abstract interface class IInjector {
  /// Registers a dependency as a **factory** with a specific key.
  ///
  /// A new instance is created every time [get] is called.
  ///
  /// Example:
  /// ```dart
  /// injector.addFactory<MyController>((i) => MyController(), key: 'login');
  /// ```
  IInjector addFactory<T>(T Function(IInjector i) builder, {String? key});

  /// Registers a dependency as a **singleton** with a specific key.
  ///
  /// The instance is created immediately and reused across the app.
  ///
  /// Example:
  /// ```dart
  /// injector.addSingleton<AppConfig>((i) => AppConfig(), key: 'prod');
  /// ```
  IInjector addSingleton<T>(T Function(IInjector i) builder, {String? key});

  /// Registers a dependency as a **lazy singleton** with a specific key.
  ///
  /// The instance is created only once on first access.
  ///
  /// Example:
  /// ```dart
  /// injector.addLazySingleton<AnalyticsService>((i) => AnalyticsService(), key: 'firebase');
  /// ```
  IInjector addLazySingleton<T>(T Function(IInjector i) builder, {String? key});

  /// Retrieves an instance of type [T] from the injector using a specific key.
  ///
  /// Throws if the key has not been registered.
  ///
  /// Example:
  /// ```dart
  /// final auth = injector.get<AuthService>(key: 'oauth');
  /// ```
  T get<T>({String? key});

  /// Returns `true` if a dependency with the given key is already registered.
  ///
  /// Example:
  /// ```dart
  /// if (!injector.isRegistered<AuthService>(key: 'oauth')) {
  ///   injector.addSingleton<AuthService>((i) => AuthService(), key: 'oauth');
  /// }
  /// ```
  bool isRegistered<T>({String? key});

  /// Returns a set of all registered types.
  ///
  /// This is useful for debugging or introspection.
  Set<Type> get registeredTypes;

  /// Returns a set of all registered binding keys.
  ///
  /// This is useful for debugging or introspection of key-based bindings.
  Set<BindingKey> get registeredKeys;

  /// Clears all registered dependencies and disposes any disposable ones.
  ///
  /// After this call, the injector is empty.
  void clearAll();

  /// Disposes the instance of the given type [T] with optional key, if it exists.
  ///
  /// Has no effect if the instance was never created or is not disposable.
  void dispose<T>({String? key});

  /// Disposes the instance registered under a raw [Type].
  ///
  /// Useful for cases where the type is not known at compile time.
  void disposeByType(Type type);

  /// Disposes the instance registered with a specific [BindingKey].
  ///
  /// Useful for disposing key-specific bindings.
  void disposeByKey(BindingKey key);
}
