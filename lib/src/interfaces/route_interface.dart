// coverage:ignore-file

/// Marker interface for defining a route structure within the Modugo ecosystem.
///
/// This interface is used to represent any type that is considered a route,
/// such as [ChildRoute], [ModuleRoute], [ShellModuleRoute], or other
/// specialized extensions.
///
/// Even though it does not declare any methods or properties, this interface
/// enables consistent typing and polymorphism across the routing system,
/// allowing different route types to be handled in a uniform way.
///
/// Example:
/// ```dart
/// List<IRoute> routes() => [
///   ChildRoute(path: '/home', child: (_, _) => const HomePage()),
///   ModuleRoute(path: '/profile', module: ProfileModule()),
/// ];
/// ```
abstract interface class IRoute {
  /// Base constructor.
  ///
  /// Since this is a marker interface, no behavior is defined.
  IRoute();
}
