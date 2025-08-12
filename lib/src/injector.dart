import 'dart:async';

import 'package:modugo/src/binds/factory_bind.dart';
import 'package:modugo/src/binds/singleton_bind.dart';
import 'package:modugo/src/binds/lazy_singleton_bind.dart';

import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

import 'package:modugo/src/routes/models/binding_key_model.dart';

/// A singleton dependency injector that manages the registration,
/// retrieval, and disposal of services and objects within Modugo.
///
/// The [Injector] supports:
/// - factory bindings (a new instance on every access)
/// - singleton bindings (eager initialization)
/// - lazy singleton bindings (instantiated on first access)
///
/// It also exposes lifecycle management methods like [dispose], [disposeByType],
/// and [clearAll] for safe memory cleanup.
///
/// Example:
/// ```dart
/// final injector = Injector()
///   ..addSingleton((i) => AppConfig())
///   ..addFactory((i) => LoginController());
///
/// final controller = injector.get<LoginController>();
/// ```
final class Injector implements IInjector {
  /// Internal singleton instance of the [Injector].
  static final Injector _instance = Injector._();

  /// Private constructor to enforce singleton usage.
  Injector._();

  /// Returns the singleton instance of the [Injector].
  factory Injector() => _instance;

  /// Internal registry that maps a [BindingKeyModel] to its corresponding [IBind].
  final Map<BindingKeyModel, IBind<Object?>> _bindings = {};

  /// Stores all dependency instances that have already been resolved.
  ///
  /// - **Key**: A [BindingKeyModel] representing the unique identifier of a binding.
  /// - **Value**: The concrete instance of the dependency associated with that key.
  ///
  /// This cache ensures that once a dependency is resolved—either synchronously
  /// or asynchronously—it can be retrieved immediately without re-instantiation.
  ///
  /// It is primarily used to:
  /// 1. Improve performance by avoiding repeated dependency creation.
  /// 2. Guarantee that synchronous `get<T>()` calls return already-initialized instances
  ///    when all dependencies have been preloaded using `resolveAll()`.
  ///
  /// See also:
  /// - [ensureInitialized] for preloading dependencies.
  /// - [BindingKeyModel] for key structure.
  final Map<BindingKeyModel, Object> _resolvedInstances = {};

  /// Returns the set of all types currently registered in the injector.
  @override
  Set<Type> get registeredTypes =>
      _bindings.keys.map((key) => key.type).toSet();

  /// Returns the set of all binding keys currently registered in the injector.
  @override
  Set<BindingKeyModel> get registeredKeys => _bindings.keys.toSet();

  /// Creates a [BindingKeyModel] for type [T] with optional key string.
  BindingKeyModel<T> _createKey<T>({String? key}) =>
      BindingKeyModel.fromString<T>(key);

  /// Registers a factory bind for type [T], creating a new instance on every access.
  @override
  Injector addFactory<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  }) {
    final bindingKey = _createKey<T>(key: key);
    _bindings[bindingKey] = FactoryBind<T>(builder);

    return this;
  }

  /// Registers a singleton bind for type [T], creating and storing the instance immediately.
  @override
  Injector addSingleton<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  }) {
    final bindingKey = _createKey<T>(key: key);
    _bindings[bindingKey] = SingletonBind<T>(builder);

    return this;
  }

  /// Registers a lazy singleton bind for type [T], creating the instance on first access.
  @override
  Injector addLazySingleton<T>(
    FutureOr<T> Function(IInjector i) builder, {
    String? key,
  }) {
    final bindingKey = _createKey<T>(key: key);
    _bindings[bindingKey] = LazySingletonBind<T>(builder);

    return this;
  }

  /// Returns `true` if a bind of type [T] with the given key has already been registered.
  @override
  bool isRegistered<T>({String? key}) {
    final bindingKey = _createKey<T>(key: key);
    return _bindings.containsKey(bindingKey);
  }

  /// Disposes and unregisters the bind with the specific [BindingKeyModel].
  @override
  void disposeByKey(BindingKeyModel key) {
    final bind = _bindings.remove(key);
    bind?.dispose();
  }

  /// Disposes and unregisters the bind of type [T] with the given key, if it exists.
  ///
  /// If the bind supports disposal (e.g., implements [Sink], [ChangeNotifier], etc.),
  /// it will be properly cleaned up.
  @override
  void dispose<T>({String? key}) {
    final bindingKey = _createKey<T>(key: key);
    final bind = _bindings.remove(bindingKey);
    bind?.dispose();
  }

  /// Disposes all registered binds and clears the injector.
  ///
  /// This is typically used during teardown or hot-restart handling.
  @override
  void clearAll() {
    for (final bind in _bindings.values) {
      bind.dispose();
    }

    _bindings.clear();
    _resolvedInstances.clear();
  }

  /// Disposes and unregisters the bind associated with the given [type].
  @override
  void disposeByType(Type type) {
    // Find all bindings with this type and dispose them
    final keysToRemove =
        _bindings.keys.where((key) => key.type == type).toList();
    for (final key in keysToRemove) {
      final bind = _bindings.remove(key);
      bind?.dispose();
    }
  }

  /// Resolves and initializes all asynchronous bindings registered in the injector.
  ///
  /// This method iterates through all registered bindings and ensures that
  /// any asynchronous factories, singletons, or lazy singletons are awaited
  /// and their instances fully created.
  ///
  /// Resolved instances are cached internally (_resolvedInstances) to allow
  /// synchronous retrieval afterwards via `get<T>()`.
  ///
  /// Calling this method before accessing dependencies guarantees that all
  /// asynchronous initializations have completed, enabling synchronous usage.
  ///
  /// Example:
  /// ```dart
  /// await injector.resolver();
  /// final service = injector.get<MyService>(); // synchronous access, safe now
  /// ```
  @override
  FutureOr<void> ensureInitialized() async {
    for (final entry in _bindings.entries) {
      final key = entry.key;
      final bind = entry.value;

      // Await the resolution of the binding's instance, whether sync or async.
      final instance = await Future.value(bind.get(this));

      // Cache the resolved instance for synchronous retrieval later.
      _resolvedInstances[key] = instance!;
    }
  }

  /// Retrieves an instance of type [T] registered in the injector, optionally keyed.
  ///
  /// This method supports both synchronous and asynchronous bindings,
  /// always returning a `FutureOr<T>`. If the binding returns a `Future<T>`,
  /// this method will `await` and resolve it before returning.
  ///
  /// Throws an [Exception] if no binding has been registered for the requested type and key.
  ///
  /// Example usage:
  /// ```dart
  /// // Synchronous usage (if binding is synchronous)
  /// final service = injector.get<MyService>();
  ///
  /// // Asynchronous usage (await if binding is asynchronous)
  /// final asyncService = await injector.get<MyService>();
  /// ```
  ///
  /// Internally, the method:
  /// 1. Constructs a [BindingKeyModel] from the type [T] and optional [key].
  /// 2. Finds the corresponding binding in the internal registry.
  /// 3. Calls the binding's `get` method, which may return an instance or a Future.
  /// 4. Awaits the result if necessary, then returns the instance.
  @override
  T get<T>({String? key}) {
    final bindingKey = _createKey<T>(key: key);

    if (_resolvedInstances.containsKey(bindingKey)) {
      return _resolvedInstances[bindingKey] as T;
    }

    final bind = _bindings[bindingKey];
    if (bind == null) {
      throw Exception('Bind not found for $bindingKey');
    }

    final instance = bind.get(this) as FutureOr<T>;
    if (instance is Future) {
      throw Exception(
        'Instance for $bindingKey is asynchronous and not resolved yet. '
        'Call resolver() before accessing synchronously.',
      );
    }

    _resolvedInstances[bindingKey] = instance!;

    return instance;
  }
}
