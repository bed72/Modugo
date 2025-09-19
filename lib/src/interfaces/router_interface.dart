import 'package:modugo/modugo.dart';

mixin IRouter {
  /// List of navigation routes this module exposes.
  ///
  /// Routes can be [ChildRoute], [ModuleRoute], [ShellModuleRoute], etc.
  /// Defaults to an empty list.
  List<IRoute> routes() => const [];
}
