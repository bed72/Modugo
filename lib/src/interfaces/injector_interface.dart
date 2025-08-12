// coverage:ignore-file

import 'dart:async';

import 'package:modugo/src/routes/models/binding_key_model.dart';

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
  /// Clears all registered dependencies and disposes any disposable ones.
  ///
  /// After this call, the injector is empty.
  void clearAll();

  /// Retrieves an instance of type [T] from the injector using a specific key.
  ///
  /// Throws if the key has not been registered.
  ///
  /// Example:
  /// ```dart
  /// final auth = injector.get<AuthService>(key: 'oauth');
  /// ```
  T get<T>({String? key});

  /// Resolves all asynchronous dependency bindings registered in the module.
  ///
  /// This method ensures that all asynchronous dependencies are fully
  /// instantiated and ready for synchronous retrieval afterwards.
  ///
  /// It is intended to be called during module initialization or before
  /// accessing injected services to guarantee that all async setup
  /// has been completed.
  ///
  /// Implementations should:
  /// - Await the resolution of any async singleton, lazy singleton, or factory bindings.
  /// - Prepare the module so that subsequent synchronous calls to `get<T>()`
  ///   return ready-to-use instances without awaiting.
  ///
  /// Example:
  /// ```dart
  /// await myModule.resolver();
  /// final service = myModule.get<MyService>(); // Synchronous access, safe to use
  /// ```
  FutureOr<void> ensureInitialized();

  /// Returns a set of all registered types.
  ///
  /// This is useful for debugging or introspection.
  Set<Type> get registeredTypes;

  /// Disposes the instance of the given type [T] with optional key, if it exists.
  ///
  /// Has no effect if the instance was never created or is not disposable.
  void dispose<T>({String? key});

  /// Disposes the instance registered under a raw [Type].
  ///
  /// Useful for cases where the type is not known at compile time.
  void disposeByType(Type type);

  /// Returns `true` if a dependency with the given key is already registered.
  ///
  /// Example:
  /// ```dart
  /// if (!injector.isRegistered<AuthService>(key: 'oauth')) {
  ///   injector.addSingleton<AuthService>((i) => AuthService(), key: 'oauth');
  /// }
  /// ```
  bool isRegistered<T>({String? key});

  /// Disposes the instance registered with a specific [BindingKeyModel].
  ///
  /// Useful for disposing key-specific bindings.
  void disposeByKey(BindingKeyModel key);

  /// Returns a set of all registered binding keys.
  ///
  /// This is useful for debugging or introspection of key-based bindings.
  Set<BindingKeyModel> get registeredKeys;

  /// Registers a dependency as a **factory** with a specific key.
  ///
  /// A new instance is created every time [get] is called.
  ///
  /// Example:
  /// ```dart
  /// injector.addFactory<MyController>((i) => MyController(), key: 'login');
  /// ```
  IInjector addFactory<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  });

  /// Registers a dependency as a **singleton** with a specific key.
  ///
  /// The instance is created immediately and reused across the app.
  ///
  /// Example:
  /// ```dart
  /// injector.addSingleton<AppConfig>((i) => AppConfig(), key: 'prod');
  /// ```
  IInjector addSingleton<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  });

  /// Registers a dependency as a **lazy singleton** with a specific key.
  ///
  /// The instance is created only once on first access.
  ///
  /// Example:
  /// ```dart
  /// injector.addLazySingleton<AnalyticsService>((i) => AnalyticsService(), key: 'firebase');
  /// ```
  IInjector addLazySingleton<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  });
}
