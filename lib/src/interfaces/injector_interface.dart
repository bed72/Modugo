// coverage:ignore-file

abstract interface class IInjector {
  IInjector addFactory<T>(T Function(IInjector i) builder);
  IInjector addSingleton<T>(T Function(IInjector i) builder);
  IInjector addLazySingleton<T>(T Function(IInjector i) builder);

  T get<T>();
  bool isRegistered<T>();

  Set<Type> get registeredTypes;

  void clearAll();
  void dispose<T>();
  void disposeByType(Type type);
}
