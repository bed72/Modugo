import 'package:modugo/src/binds/factory_bind.dart';
import 'package:modugo/src/binds/singleton_bind.dart';
import 'package:modugo/src/binds/lazy_singleton_bind.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

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

  /// Internal registry that maps a [Type] to its corresponding [IBind].
  final Map<Type, IBind<Object?>> _bindings = {};

  /// Returns the set of all types currently registered in the injector.
  @override
  Set<Type> get registeredTypes => _bindings.keys.toSet();

  /// Registers a factory bind for type [T], creating a new instance on every access.
  @override
  Injector addFactory<T>(T Function(Injector i) builder) {
    _bindings[T] = FactoryBind<T>(builder);
    return this;
  }

  /// Registers a singleton bind for type [T], creating and storing the instance immediately.
  @override
  Injector addSingleton<T>(T Function(Injector i) builder) {
    _bindings[T] = SingletonBind<T>(builder);
    return this;
  }

  /// Registers a lazy singleton bind for type [T], creating the instance on first access.
  @override
  Injector addLazySingleton<T>(T Function(Injector i) builder) {
    _bindings[T] = LazySingletonBind<T>(builder);
    return this;
  }

  /// Returns `true` if a bind of type [T] has already been registered.
  @override
  bool isRegistered<T>() => _bindings.containsKey(T);

  /// Disposes and unregisters the bind of type [T], if it exists.
  ///
  /// If the bind supports disposal (e.g., implements [Sink], [ChangeNotifier], etc.),
  /// it will be properly cleaned up.
  @override
  void dispose<T>() {
    final bind = _bindings.remove(T);
    bind?.dispose();
  }

  /// Disposes and unregisters the bind associated with the given [type].
  @override
  void disposeByType(Type type) {
    final bind = _bindings.remove(type);
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

  /// Retrieves the instance of type [T].
  ///
  /// Throws an [Exception] if no bind has been registered for [T].
  ///
  /// Example:
  /// ```dart
  /// final service = Injector().get<MyService>();
  /// ```
  @override
  T get<T>() {
    final bind = _bindings[T];
    if (bind == null) throw Exception('Bind not found for type $T');

    return bind.get(this) as T;
  }
}
