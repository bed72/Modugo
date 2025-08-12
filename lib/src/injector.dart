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

  /// Returns the set of all types currently registered in the injector.
  @override
  Set<Type> get registeredTypes =>
      _bindings.keys.map((key) => key.type).toSet();

  /// Returns the set of all binding keys currently registered in the injector.
  @override
  Set<BindingKeyModel> get registeredKeys => _bindings.keys.toSet();

  /// Creates a [BindingKeyModel] for type [T] with optional key string.
  BindingKeyModel<T> _createKey<T>({String? key}) {
    return BindingKeyModel.fromString<T>(key);
  }

  /// Registers a factory bind for type [T], creating a new instance on every access.
  @override
  Injector addFactory<T>(T Function(IInjector i) builder, {String? key}) {
    final bindingKey = _createKey<T>(key: key);
    _bindings[bindingKey] = FactoryBind<T>(builder);
    return this;
  }

  /// Registers a singleton bind for type [T], creating and storing the instance immediately.
  @override
  Injector addSingleton<T>(T Function(IInjector i) builder, {String? key}) {
    final bindingKey = _createKey<T>(key: key);
    _bindings[bindingKey] = SingletonBind<T>(builder);
    return this;
  }

  /// Registers a lazy singleton bind for type [T], creating the instance on first access.
  @override
  Injector addLazySingleton<T>(T Function(IInjector i) builder, {String? key}) {
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

  /// Disposes and unregisters the bind with the specific [BindingKeyModel].
  @override
  void disposeByKey(BindingKeyModel key) {
    final bind = _bindings.remove(key);
    bind?.dispose();
  }

  /// Disposes all registered binds and clears the injector.
  ///
  /// This is typically used during teardown or hot-restart handling.
  @override
  void clearAll() {
    for (final b in _bindings.values) {
      b.dispose();
    }
    _bindings.clear();
  }

  /// Retrieves the instance of type [T] with the given key.
  ///
  /// Throws an [Exception] if no bind has been registered for the key.
  ///
  /// Example:
  /// ```dart
  /// final service = Injector().get<MyService>();
  /// final keyedService = Injector().get<MyService>(key: 'specific');
  /// ```
  @override
  T get<T>({String? key}) {
    final bindingKey = _createKey<T>(key: key);
    final bind = _bindings[bindingKey];
    if (bind == null) {
      throw Exception('Bind not found for key $bindingKey');
    }

    return bind.get(this) as T;
  }
}
