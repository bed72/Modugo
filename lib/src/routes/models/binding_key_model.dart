// ignore_for_file: overridden_fields

import 'package:flutter/foundation.dart';

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
@immutable
final class BindingKeyModel<T> {
  /// The type of the dependency this key represents.
  final Type type;

  /// The unique identifier for this binding.
  final String key;

  /// Creates a new [BindingKeyModel] with the given [key] and inferred type [T].
  const BindingKeyModel(this.key) : type = T;

  /// Creates a [BindingKeyModel] for the given type without a specific key.
  ///
  /// This is equivalent to the default behavior where only type is used.
  const BindingKeyModel.defaultKey() : key = '', type = T;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingKeyModel &&
          key == other.key &&
          type == other.type &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => key.hashCode ^ type.hashCode;

  @override
  String toString() => 'BindingKey<$type>("$key")';

  /// Creates a [BindingKeyModel] from a raw [Type] and [key].
  ///
  /// Useful when the type is only known at runtime.
  factory BindingKeyModel.fromType(Type type, String key) =>
      _TypedBindingKeyModel(type, key);

  /// Creates a [BindingKeyModel] for type [T] from a [String] key.
  ///
  /// If key is null or empty, creates a default key for backward compatibility.
  static BindingKeyModel<T> fromString<T>(String? key) {
    return key == null || key.isEmpty
        ? BindingKeyModel<T>.defaultKey()
        : BindingKeyModel<T>(key);
  }
}

/// Internal implementation for runtime type-based keys.
final class _TypedBindingKeyModel<T> extends BindingKeyModel<T> {
  @override
  final Type type;

  @override
  final String key;

  const _TypedBindingKeyModel(this.type, this.key) : super(key);
}
