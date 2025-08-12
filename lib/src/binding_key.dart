/// A key that uniquely identifies a dependency binding in the injector.
///
/// This allows multiple instances of the same type to be registered
/// with different keys, solving the problem of type collision.
///
/// Example:
/// ```dart
/// // Register multiple instances of the same type with different keys
/// injector
///   ..addSingleton<Database>((i) => Database.primary(), key: 'primary')
///   ..addSingleton<Database>((i) => Database.cache(), key: 'cache');
///
/// // Retrieve specific instances using their keys
/// final primaryDb = injector.get<Database>(key: 'primary');
/// final cacheDb = injector.get<Database>(key: 'cache');
/// ```
final class BindingKey<T> {
  /// The unique identifier for this binding.
  final String key;

  /// The type of the dependency this key represents.
  final Type type;

  /// Creates a new [BindingKey] with the given [key] and inferred type [T].
  const BindingKey(this.key) : type = T;

  /// Creates a [BindingKey] for the given type without a specific key.
  /// 
  /// This is equivalent to the default behavior where only type is used.
  const BindingKey.defaultKey() : key = '', type = T;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingKey &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          type == other.type;

  @override
  int get hashCode => key.hashCode ^ type.hashCode;

  @override
  String toString() => 'BindingKey<$type>("$key")';

  /// Creates a [BindingKey] from a raw [Type] and [key].
  /// 
  /// Useful when the type is only known at runtime.
  factory BindingKey.fromType(Type type, String key) => _TypedBindingKey(type, key);
  
  /// Creates a [BindingKey] for type [T] from a [String] key.
  /// 
  /// If key is null or empty, creates a default key for backward compatibility.
  static BindingKey<T> fromString<T>(String? key) {
    return key == null || key.isEmpty ? BindingKey<T>.defaultKey() : BindingKey<T>(key);
  }
}

/// Internal implementation for runtime type-based keys.
final class _TypedBindingKey<T> extends BindingKey<T> {
  @override
  final Type type;

  @override
  final String key;

  const _TypedBindingKey(this.type, this.key) : super(key);
}

/// Extension to create default keys for backward compatibility.
extension BindingKeyExtensions on Type {
  /// Creates a default [BindingKey] for this type.
  BindingKey get defaultKey => BindingKey.fromType(this, '');
}
