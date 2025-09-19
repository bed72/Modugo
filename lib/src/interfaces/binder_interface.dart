mixin IBinder {
  /// Registers all dependency injection bindings for this module.
  ///
  /// Override this method to declare your dependencies using the [GetIt].
  void binds() {}

  /// List of imported modules that this module depends on.
  ///
  /// Allows modular composition by importing submodules.
  /// Defaults to an empty list.
  List<IBinder> imports() => const [];
}
