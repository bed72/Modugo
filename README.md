<p align="center">
  <img src="https://raw.githubusercontent.com/bed72/Modugo/master/images/banner.png" alt="Modugo Logo" />
</p>

# Modugo

**Modugo** is a modular dependency and routing manager for Flutter/Dart that organizes the lifecycle of modules, dependencies, and routes. It is inspired by the modular architecture from [go_router_modular](https://pub.dev/packages/go_router_modular).

The main difference is that Modugo provides full control and decoupling of **automatic dependency injection and disposal based on navigation**, with detailed logs and an extensible structure.

---

## 📦 Features

- Per-module registration of **dependencies** with `singleton`, `factory`, and `lazySingleton`
- **Automatic lifecycle management** triggered by route access or exit
- Support for **imported modules** (nested modules)
- **Automatic disposal** of unused dependencies
- Integration with **GoRouter**
- Support for `ShellRoute` and `StatefulShellRoute`
- Detailed and configurable logging

---

## 🚀 Installation

```yaml
dependencies:
  modugo: x.x.x
```

---

## 🔹 Example Project Structure

```
/lib
  /modules
    /home
      home_page.dart
      home_module.dart
    /profile
      profile_page.dart
      profile_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

---

## 🟢 Getting Started

### main.dart

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
```

---

### app_widget.dart

```dart
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modugo.routerConfig,
      title: 'Modugo App',
    );
  }
}
```

---

### app_module.dart

```dart
class AppModule extends Module {
  @override
  List<void Function(IInjector)> get binds => [
    (i) => i.addSingleton<AuthService>((_) => AuthService()),
  ];

  @override
  List<IModule> get routes => [
    ModuleRoute('/', module: HomeModule()),
    ModuleRoute('/profile', module: ProfileModule()),
  ];
}
```

---

## 💊 Dependency Injection

### Supported Types

- `addSingleton<T>((i) => ...)`
- `addLazySingleton<T>((i) => ...)`
- `addFactory<T>((i) => ...)`

### Example

```dart
class HomeModule extends Module {
  @override
  List<void Function(IInjector)> get binds => [
    (i) => i
      ..addSingleton<HomeController>((i) => HomeController(i.get()))
      ..addLazySingleton<Repository>((i) => RepositoryImpl())
      ..addFactory<DateTime>((_) => DateTime.now()),
  ];

  @override
  List<IModule> get routes => [
    ChildRoute('/home', child: (context, state) => const HomePage()),
  ];
}
```

---

## ⚖️ Lifecycle

- Dependencies are **automatically registered** when accessing a module route.
- When all routes of that module are exited, dependencies are **automatically disposed**.
- Disposal respects `.dispose()`, `.close()`, or `StreamController.close()`.
- The root `AppModule` is **never disposed**.
- Dependencies in imported modules are shared and removed only when all consumers are disposed.

---

## 🚣 Navigation

### `ChildRoute`

```dart
ChildRoute('/home', child: (context, state) => const HomePage()),
```

### `ModuleRoute`

```dart
ModuleRoute('/profile', module: ProfileModule()),
```

### `ShellModuleRoute`

```dart
ShellModuleRoute(
  builder: (context, state, child) => MyShell(child: child),
  routes: [
    ChildRoute('/tab1', child: (_, __) => const Tab1Page()),
    ChildRoute('/tab2', child: (_, __) => const Tab2Page()),
  ],
  binds: [
    (i) => i.addLazySingleton(() => TabController()),
  ],
)
```

### `StatefulShellModuleRoute`

```dart
StatefulShellModuleRoute(
  builder: (context, state, shell) => BottomNavBar(shell: shell),
  routes: [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
    ModuleRoute(path: '/favorites', module: FavoritesModule()),
  ],
)
```

---

## 🔍 Accessing Dependencies

```dart
final controller = Modugo.get<HomeController>();
```

Or via context extension:

```dart
final controller = context.read<HomeController>();
```

---

## 🧰 Logging and Diagnostics

```dart
Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,
);
```

- All logs pass through the `Logger` class, which can be extended or customized.
- Logs include injection, disposal, navigation, and errors.

---

## 🧼 Best Practices

- Always specify explicit types for `addSingleton`, `addLazySingleton`, and `addFactory`.
- Divide your app into **small, cohesive modules**.
- Use `AppModule` only for **global dependencies**.

---

## 🤝 Contributions

Pull requests, suggestions, and improvements are welcome!

---

## ⚙️ License

MIT ©
