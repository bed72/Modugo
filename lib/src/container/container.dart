import 'package:modugo/src/container/bind.dart';

/// A lightweight dependency injection container with module-scoped lifecycle.
///
/// [Container] manages dependency registration, resolution, and disposal.
/// Each binding can be associated with a module tag, enabling scoped disposal
/// via [disposeModule].
///
/// ### Registration
/// - [add] — factory: new instance per `get<T>()` call.
/// - [addSingleton] — singleton with optional `onDispose` callback.
/// - [addLazySingleton] — lazy singleton with optional `onDispose` callback.
///
/// ### Resolution
/// - [get] — resolves or throws [StateError].
/// - [tryGet] — resolves or returns `null`.
///
/// ### Disposal
/// - [disposeModule] — disposes all bindings of a module (by tag), in reverse order.
/// - [disposeAll] — resets the entire container.
///
/// ### Example
/// ```dart
/// final container = Container();
///
/// container.addSingleton<Database>(
///   () => Database(),
///   onDispose: (db) => db.close(),
/// );
///
/// final db = container.get<Database>();
/// container.disposeModule('MyModule');
/// ```
final class Container {
  /// The active tag during [binds] execution.
  ///
  /// Set automatically by [Module] before calling `binds()`.
  /// All registrations made while [activeTag] is set will be associated
  /// with this tag for scoped disposal.
  String? activeTag;

  /// All registered bindings, keyed by type.
  final Map<Type, Bind> _binds = {};

  /// Reverse index: tag → list of types registered under that tag.
  /// Uses a [List] to preserve insertion order for reverse disposal.
  final Map<String, List<Type>> _tagIndex = {};

  /// Tracks types currently being resolved, to detect circular dependencies.
  final Set<Type> _resolving = {};

  // ─── Registration ─────────────────────────────────────────

  /// Registers a factory binding.
  ///
  /// A new instance is created on every [get] call.
  /// Factories do not keep references and are not affected by [disposeModule].
  void add<T extends Object>(T Function() create) {
    _register<T>(create: create, type: .factory);
  }

  /// Registers a singleton binding.
  ///
  /// The instance is created on the first [get] call and cached.
  /// [onDispose] is called when the module is disposed via [disposeModule].
  void addSingleton<T extends Object>(
    T Function() create, {
    void Function(T)? onDispose,
  }) {
    _register<T>(create: create, type: .singleton, onDispose: onDispose);
  }

  /// Registers a lazy singleton binding.
  ///
  /// Behaves like [addSingleton] — instance created on first access.
  /// [onDispose] is called when the module is disposed via [disposeModule].
  void addLazySingleton<T extends Object>(
    T Function() create, {
    void Function(T)? onDispose,
  }) {
    _register<T>(create: create, type: .lazySingleton, onDispose: onDispose);
  }

  void _register<T extends Object>({
    required T Function() create,
    required BindType type,
    void Function(T)? onDispose,
  }) {
    if (_binds.containsKey(T)) {
      final existing = _binds[T]!;
      throw StateError(
        'Binding for type $T is already registered'
        '${existing.tag != null ? ' (tag: ${existing.tag})' : ''}. '
        'Cannot register the same type twice. '
        'Check your binds() and imports() for duplicates.',
      );
    }

    final tag = activeTag;

    _binds[T] = Bind<T>(
      tag: tag,
      type: type,
      create: create,
      onDispose: onDispose,
    );

    if (tag != null) {
      _tagIndex.putIfAbsent(tag, () => []).add(T);
    }
  }

  // ─── Resolution ───────────────────────────────────────────

  /// Resolves an instance of type [T].
  ///
  /// Throws [StateError] if no binding is found or if a circular
  /// dependency is detected.
  T get<T extends Object>() {
    if (_resolving.contains(T)) {
      final chain = [..._resolving, T].map((t) => t.toString()).join(' → ');
      throw StateError(
        'Circular dependency detected: $chain. '
        'Review your binds() to break the cycle.',
      );
    }

    final bind = _binds[T];
    if (bind == null) {
      throw StateError(
        'No binding found for type $T. '
        'Did you forget to register it in binds()?',
      );
    }

    _resolving.add(T);
    try {
      return bind.resolve() as T;
    } finally {
      _resolving.remove(T);
    }
  }

  /// Tries to resolve an instance of type [T].
  ///
  /// Returns `null` if no binding is found. Still throws on circular
  /// dependency to prevent silent failures.
  T? tryGet<T extends Object>() {
    if (!_binds.containsKey(T)) return null;
    return get<T>();
  }

  /// Returns `true` if a binding for type [T] exists in the container.
  bool isRegistered<T extends Object>() => _binds.containsKey(T);

  // ─── Disposal ─────────────────────────────────────────────

  /// Disposes all bindings associated with the given module [tag].
  ///
  /// Bindings are disposed in **reverse registration order** so that
  /// dependencies registered later (which may depend on earlier ones)
  /// are cleaned up first.
  ///
  /// For each binding:
  /// 1. Calls [onDispose] callback (if defined and instance exists).
  /// 2. Removes the binding from the container.
  ///
  /// After this call, [get] for types from this module will throw [StateError].
  /// Safe to call with a non-existent tag (no-op).
  void disposeModule(String tag) {
    final types = _tagIndex.remove(tag);
    if (types == null) return;

    for (final type in types.reversed) {
      _binds[type]?.dispose();
      _binds.remove(type);
    }
  }

  /// Disposes all bindings in the container.
  ///
  /// Calls [onDispose] for every singleton that has a live instance,
  /// then clears all registrations. Used in tests or full app reset.
  void disposeAll() {
    final allTypes = _tagIndex.values.expand((types) => types).toList();
    final globalTypes = _binds.keys
        .where((type) => !allTypes.contains(type))
        .toList();

    // Dispose tagged binds in reverse order per tag
    for (final types in _tagIndex.values) {
      for (final type in types.reversed) {
        _binds[type]?.dispose();
      }
    }

    // Dispose global (untagged) binds
    for (final type in globalTypes.reversed) {
      _binds[type]?.dispose();
    }

    _binds.clear();
    _tagIndex.clear();
  }
}
