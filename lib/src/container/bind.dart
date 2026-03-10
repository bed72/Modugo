/// The type of lifecycle a binding follows.
enum BindType {
  /// New instance created on every `get<T>()` call.
  /// No reference is kept; `onDispose` is never called.
  factory,

  /// Single instance, created on first `get<T>()`.
  /// Same instance returned on subsequent calls.
  singleton,

  /// Same behavior as [singleton] — single instance created on first access.
  /// Exists as a distinct type for semantic clarity and future eager-init support.
  lazySingleton,
}

/// Represents a single dependency registration in the [Container].
///
/// Each [Bind] holds a factory function to create the instance,
/// an optional [onDispose] callback, and tracks the created instance
/// for singleton types.
final class Bind<T extends Object> {
  T? _instance;
  final String? tag;
  final BindType type;
  final T Function() create;
  final void Function(T instance)? onDispose;

  Bind({this.onDispose, required this.type, required this.create, this.tag});

  /// Whether this bind has a live instance (only for singletons).
  bool get hasInstance => _instance != null;

  /// Resolves the instance according to the binding type.
  ///
  /// - [BindType.factory]: always creates a new instance.
  /// - [BindType.singleton] / [BindType.lazySingleton]: creates on first call,
  ///   returns cached instance on subsequent calls.
  T resolve() => switch (type) {
    .factory => create(),
    .singleton => _instance ??= create(),
    .lazySingleton => _instance ??= create(),
  };

  /// Calls [onDispose] if there is a live instance and a callback defined.
  /// Clears the internal reference after disposal.
  void dispose() {
    if (_instance != null && onDispose != null) onDispose!(_instance as T);
    _instance = null;
  }
}
