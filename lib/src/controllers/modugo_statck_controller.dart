import 'package:flutter/foundation.dart';

/// A simple stack controller for managing navigation history externally.
///
/// The [ModugoStackController] provides a lightweight, in-memory stack
/// to help track the navigation flow independently of the [GoRouter] or any
/// internal routing mechanism. It is especially useful in modular
/// architectures, where popping to a previous route isn't straightforward
/// due to multiple navigator keys or isolated route scopes.
///
/// This controller is a singleton and can be accessed via
/// [ModugoStackController.instance].
@immutable
final class ModugoStackController {
  final List<String> _stack = [];

  /// Singleton instance of [ModugoStackController].
  static final ModugoStackController instance = ModugoStackController._();

  ModugoStackController._();

  /// Clears all entries from the stack.
  void clear() => _stack.clear();

  /// Returns `true` if there is at least one path in the stack.
  bool get canPop => _stack.isNotEmpty;

  /// Returns an unmodifiable copy of the current stack.
  ///
  /// This is useful for inspection or debugging purposes.
  List<String> get stack => List.unmodifiable(_stack);

  /// Adds a list of [paths] to the stack, preserving existing entries
  /// and avoiding duplicates.
  ///
  /// Existing paths in the stack are preserved in order.
  /// Only new, non-duplicated paths from [paths] are added at the end.
  ///
  /// Example:
  /// ```dart
  /// controller.stack = ['/a', '/b'];
  /// controller.stack = ['/b', '/c'];
  /// print(controller.stack); // ['/a', '/b', '/c']
  /// ```
  set stack(List<String> paths) {
    for (final path in paths) {
      if (!_stack.contains(path)) {
        _stack.add(path);
      }
    }
  }

  /// Key used in the `extra` map of navigation calls to explicitly store
  /// the target path for the route transition.
  ///
  /// This is useful when you want to track the destination path separately
  /// or when resolving it dynamically inside route guards, middlewares,
  /// or page builders.
  ///
  /// Example usage:
  /// ```dart
  /// Modugo.routerConfig.go(
  ///   '/checkout',
  ///   extra: {
  ///     path: '/checkout',
  ///   },
  /// );
  /// ```
  ///
  /// Example access:
  /// ```dart
  /// final path = GoRouterState.of(context).extra?[path] as String?;
  /// ```
  String get path => 'path';

  /// Key used in the `extra` map of navigation calls to indicate that the
  /// route transition was triggered by the [ModugoStackController].
  ///
  /// This can be used in destination pages or middleware to differentiate between
  /// normal navigation and one controlled by the external backstack.
  ///
  /// Example usage:
  /// ```dart
  /// Modugo.routerConfig.go(
  ///   '/profile',
  ///   extra: {
  ///     is_external_stack_control: true,
  ///   },
  /// );
  /// ```
  ///
  /// Example check:
  /// ```dart
  /// final isControlled = GoRouterState.of(context).extra?['is_external_stack_control'] == true;
  /// ```
  String get isExternalStackControl => 'is_external_stack_control';

  /// Pops the last path from the stack and returns it.
  ///
  /// Returns `null` if the stack is empty.
  String? pop() {
    if (_stack.isNotEmpty) return _stack.removeLast();
    return null;
  }

  /// Pushes a new path onto the navigation stack.
  ///
  /// If the stack is empty or the provided [path] is different from the
  /// last pushed path, it will be added to the stack.
  /// If the stack exceeds 20 entries, the oldest entry will be removed.
  void push(String path) {
    if (_stack.isEmpty || _stack.last != path) {
      if (_stack.length >= 20) _stack.removeAt(0);
      _stack.add(path);
    }
  }
}
