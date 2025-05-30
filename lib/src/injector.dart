final class Injector {
  T get<T>() => Bind.get<T>();
}

final class Bind<T> {
  T? _instance;

  static final Map<Type, Bind> _binds = {};

  final bool isLazy;
  final bool isSingleton;
  final T Function(Injector i) factoryFunction;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = true});

  static T get<T>() => _find<T>();

  T get instance {
    if (!isSingleton) return factoryFunction(Injector());

    _instance ??= factoryFunction(Injector());

    return _instance!;
  }

  static void register<T>(Bind<T> bind) {
    _binds[T] = bind;
  }

  static Bind<T> factory<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: false, isLazy: false);

  static Bind<T> singleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: false);

  static Bind<T> lazySingleton<T>(T Function(Injector i) builder) =>
      Bind<T>(builder, isSingleton: true, isLazy: true);

  static void dispose<T>() {
    _binds.remove(T);
  }

  static void disposeByType(Type type) {
    _binds.remove(type);
  }

  static T _find<T>() {
    final bind = _binds[T];
    if (bind == null) {
      throw Exception('Bind not found for type ${T.toString()}');
    }

    return (bind as Bind<T>).instance;
  }
}
