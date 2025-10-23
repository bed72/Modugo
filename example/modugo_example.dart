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

import 'package:flutter/material.dart';

import 'package:modugo/modugo.dart';
// import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Initialize Modugo with the root module
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(
    module: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    errorBuilder: AppResolver.error,
    debugLogDiagnosticsGoRouter: true,
  );

  runApp(const AppWidget());
}

/// Resolves the root application widget and manages asynchronous dependencies.
///
/// [AppResolver] provides a single point to access the main app widget (`app`),
/// handles error navigation (`error`), and exposes all async dependencies required
/// before rendering the app.
///
/// Usage:
/// ```dart
/// runApp(AppResolver.app);
/// ```
final class AppResolver {
  /// Handles navigation when an error occurs during route resolution.
  ///
  /// Typically redirects the user to a safe route (e.g., '/').
  ///
  /// Parameters:
  /// - [context]: The current [BuildContext]
  /// - [state]: The [GoRouterState] containing routing information
  ///
  /// Returns a widget to display (can be `SizedBox.shrink()` if redirection occurs).
  static Widget error(BuildContext context, GoRouterState state) {
    context.go('/');
    return const Placeholder();
  }
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
  List<IRoute> routes() => [module(path: '/', module: HomeModule())];
}

/// The home module that handles feature-specific dependencies and routes.
final class HomeModule extends Module {
  @override
  Future<void> binds() async {
    // Example using SharedPreferences
    // i.registerSingletonAsync<SharedPreferences>(
    //   () async => await SharedPreferences.getInstance(),
    // );

    i
      ..registerSingleton<ModugoRepository>(ModugoRepositoryImpl())
      ..registerLazySingleton<HomeController>(
        () => HomeController(i.get<DateTime>(), i.get<ModugoRepository>()),
      )
      ..registerFactory<DateTime>(() => DateTime.now());
  }

  @override
  List<IRoute> routes() => [
    child(
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
