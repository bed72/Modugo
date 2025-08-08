/// A complete example using Modugo for modular routing and dependency injection.
///
/// This example includes:
/// - A repository interface and its implementation
/// - A controller that depends on the repository
/// - A module that registers all dependencies and routes
/// - A basic UI that consumes the controller
///
/// To run this example, ensure Modugo is added as a dependency in your pubspec.yaml,
/// then use `flutter run example/modugo_example.dart`.
library;

import 'package:modugo/modugo.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Modugo with the root module
  Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}

/// The root widget for the app.
final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Modugo App',
      routerConfig: Modugo.routerConfig,
    );
  }
}

/// The root module that defines app-level routes.
///
/// This module includes [HomeModule] as its child.
final class AppModule extends Module {
  @override
  List<IModule> routes() => [ModuleRoute(path: '/', module: HomeModule())];
}

/// The home module that handles feature-specific dependencies and routes.
final class HomeModule extends Module {
  @override
  void binds(IInjector i) {
    i
      ..addLazySingleton<ModugoRepository>((_) => ModugoRepositoryImpl())
      ..addSingleton<HomeController>(
        (i) => HomeController(i.get<DateTime>(), i.get<ModugoRepository>()),
      )
      ..addFactory<DateTime>((_) => DateTime.now());
  }

  @override
  List<IModule> routes() => [
    ChildRoute(
      path: '/',
      name: 'home-route',
      child: (context, _) {
        final controller = context.read<HomeController>();
        return HomeScreen(controller: controller);
      },
    ),
  ];
}

/// UI screen that displays a message from the controller.
final class HomeScreen extends StatelessWidget {
  final HomeController _controller;

  const HomeScreen({super.key, required HomeController controller})
    : _controller = controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modugo Example')),
      body: Center(child: Text(_controller.message())),
    );
  }
}

/// Controller that consumes [ModugoRepository] to provide business logic.
final class HomeController {
  final DateTime date;
  final ModugoRepository repository;

  HomeController(this.date, this.repository);

  String message() =>
      '${repository.welcome()}\n${date.weekday}-${date.month}-${date.year}';
}

/// Abstract contract for a data repository.
abstract interface class ModugoRepository {
  String welcome();
}

/// Concrete implementation of [ModugoRepository].
final class ModugoRepositoryImpl implements ModugoRepository {
  @override
  String welcome() => 'Welcome!';
}
