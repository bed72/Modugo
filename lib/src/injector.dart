import 'package:modugo/src/binds/factory_bind.dart';
import 'package:modugo/src/binds/singleton_bind.dart';
import 'package:modugo/src/binds/lazy_singleton_bind.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';
import 'package:modugo/src/interfaces/injector_interface.dart';

final class Injector implements IInjector {
  static final Injector _instance = Injector._();

  Injector._();

  factory Injector() => _instance;

  final Map<Type, IBind<Object?>> _bindings = {};

  @override
  Set<Type> get registeredTypes => _bindings.keys.toSet();

  @override
  Injector addFactory<T>(T Function(Injector i) builder) {
    _bindings[T] = FactoryBind<T>(builder);
    return this;
  }

  @override
  Injector addSingleton<T>(T Function(Injector i) builder) {
    _bindings[T] = SingletonBind<T>(builder);
    return this;
  }

  @override
  Injector addLazySingleton<T>(T Function(Injector i) builder) {
    _bindings[T] = LazySingletonBind<T>(builder);
    return this;
  }

  @override
  bool isRegistered<T>() => _bindings.containsKey(T);

  @override
  void dispose<T>() {
    final bind = _bindings.remove(T);
    bind?.dispose();
  }

  @override
  void disposeByType(Type type) {
    final bind = _bindings.remove(type);
    bind?.dispose();
  }

  @override
  void clearAll() {
    for (final b in _bindings.values) {
      b.dispose();
    }
    _bindings.clear();
  }

  @override
  T get<T>() {
    final bind = _bindings[T];
    if (bind == null) throw Exception('Bind not found for type $T');

    return _bindings[T]!.get(this) as T;
  }
}
