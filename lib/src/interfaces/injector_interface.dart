// coverage:ignore-file

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
  /// Registers a dependency as a **factory**.
  ///
  /// A new instance is created every time [get] is called.
  ///
  /// Example:
  /// ```dart
  /// injector.addFactory((i) => MyController());
  /// ```
  IInjector addFactory<T>(T Function(IInjector i) builder);

  /// Registers a dependency as a **singleton**.
  ///
  /// The instance is created immediately and reused across the app.
  ///
  /// Example:
  /// ```dart
  /// injector.addSingleton((i) => AppConfig());
  /// ```
  IInjector addSingleton<T>(T Function(IInjector i) builder);

  /// Registers a dependency as a **lazy singleton**.
  ///
  /// The instance is created only once on first access.
  ///
  /// Example:
  /// ```dart
  /// injector.addLazySingleton((i) => AnalyticsService());
  /// ```
  IInjector addLazySingleton<T>(T Function(IInjector i) builder);

  /// Retrieves an instance of type [T] from the injector.
  ///
  /// Throws if [T] has not been registered.
  ///
  /// Example:
  /// ```dart
  /// final auth = injector.get<AuthService>();
  /// ```
  T get<T>();

  /// Returns `true` if a dependency of type [T] is already registered.
  ///
  /// Example:
  /// ```dart
  /// if (!injector.isRegistered<AuthService>()) {
  ///   injector.addSingleton((i) => AuthService());
  /// }
  /// ```
  bool isRegistered<T>();

  /// Returns a set of all registered types.
  ///
  /// This is useful for debugging or introspection.
  Set<Type> get registeredTypes;

  /// Clears all registered dependencies and disposes any disposable ones.
  ///
  /// After this call, the injector is empty.
  void clearAll();

  /// Disposes the instance of the given type [T], if it exists.
  ///
  /// Has no effect if the instance was never created or is not disposable.
  void dispose<T>();

  /// Disposes the instance registered under a raw [Type].
  ///
  /// Useful for cases where the type is not known at compile time.
  void disposeByType(Type type);
}
