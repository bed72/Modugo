// coverage:ignore-file

/// Marker interface for defining a modular structure within the Modugo ecosystem.
///
/// This interface is used to represent any type that is considered a "module",
/// such as [Module] itself or other specialized extensions.
///
/// Even though it does not declare any methods or properties, this interface
/// allows for consistent typing and future-proof extensibility across the framework.
///
/// Example:
/// ```dart
/// class MyModule extends Module implements IRoute {
///   // Implementation...
/// }
/// ```
abstract interface class IRoute {
  /// Base constructor.
  ///
  /// Since this is a marker interface, no behavior is defined.
  IRoute();
}
