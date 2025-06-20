import 'package:flutter/widgets.dart';

import 'package:modugo/src/modugo.dart';

import 'app_module.dart';
import 'app_widget.dart';

/// A minimal example showing how to use Modugo for dependency injection and routing.
///
/// This example includes:
/// - A repository interface and its implementation
/// - A controller that consumes the repository
/// - A module that registers both
/// - A home screen that uses the controller injection

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
