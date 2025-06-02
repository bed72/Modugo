final class Injector {
  T get<T>() => Bind.get<T>();
}

final class Bind<T> {
  static final Map<Type, Bind> _binds = {};

  final bool isLazy;
  final bool isSingleton;
  final T Function(Injector i) factoryFunction;

  T? _cachedInstance;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = true});

  T? get maybeInstance => _cachedInstance;

  T get instance {
    if (!isSingleton) return factoryFunction(Injector());

    return _cachedInstance ??= factoryFunction(Injector());
  }

  static T get<T>() => _find<T>();

  static Bind? getBindByType(Type type) => _binds[type];

  static Bind<T> factory<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: false, isLazy: false);

  static Bind<T> singleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: false);

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: true);

  static void register<T>(Bind<T> bind) {
    _binds[T] = bind;

    if (!bind.isLazy && bind.isSingleton) {
      bind._cachedInstance = bind.factoryFunction(Injector());
    }
  }

  static void dispose<T>() {
    _binds.remove(T);
  }

  static void clearAll() {
    _binds.clear();
  }

  static void disposeByType(Type type) {
    _binds.remove(type);
  }

  static T _find<T>() {
    final bind = _binds[dynamic];

    if (bind == null) {
      throw Exception('Bind not found for type ${T.toString()}');
    }

    return (bind as Bind<T>).instance;
  }
}
