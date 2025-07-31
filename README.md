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
- Support for **persistent modules** that are never disposed
- Built-in support for **Route Guards**
- Built-in support for **Regex-based Route Matching**

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
final class AppModule extends Module {
  @override
  void binds(IInjector i) {
    i.addSingleton<AuthService>((_) => AuthService());
  }

  @override
  List<IModule> get routes => [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
  ];
}
```

---

## ♻️ Persistent Modules

By default, Modugo automatically disposes dependencies when a module is no longer active (i.e., when all its routes are exited).
For cases like bottom navigation tabs, you may want to **keep modules alive** even when they are not visible.

To do this, override the `persistent` flag:

```dart
final class HomeModule extends Module {
  @override
  bool get persistent => true;

  @override
  void binds(IInjector i) {
    i.addLazySingleton<HomeController>(() => HomeController());
  }

  @override
  List<IModule> get routes => [
    ChildRoute(path: '/', child: (_, _) => const HomePage()),
  ];
}
```

✅ Great for `StatefulShellRoute` branches  
🚫 Avoid for short-lived or heavy modules

---

## ⚖️ Lifecycle

- Dependencies are **automatically registered** when accessing a module route.
- When all routes of that module are exited, dependencies are **automatically disposed**.
- Disposal respects `.dispose()`, `.close()`, or `StreamController.close()`.
- The root `AppModule` is **never disposed**.
- Dependencies in imported modules are shared and removed only when all consumers are disposed.

---

## 🧠 Logging and Diagnostics

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

## 🚣 Navigation

### `ChildRoute`

```dart
ChildRoute(path: '/home', child: (context, state) => const HomePage()),
```

### `ModuleRoute`

```dart
ModuleRoute(path: '/profile', module: ProfileModule()),
```

### `ShellModuleRoute`

Use `ShellModuleRoute` when you want to create a navigation window **inside a specific area of your UI**, similar to `RouteOutlet` in Flutter Modular. This is commonly used in layout scenarios with menus or tabs, where only part of the screen changes based on navigation.

> ℹ️ Internally, it uses GoRouter’s `ShellRoute`.  
> Learn more: [ShellRoute docs](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html)

#### Module Setup

```dart
final class HomeModule extends Module {
  @override
  List<IModule> get routes => [
    ShellModuleRoute(
      builder: (context, state, child) => PageWidget(child: child),
      routes: [
        ChildRoute(path: '/user', child: (_, _) => const UserPage()),
        ChildRoute(path: '/config', child: (_, _) => const ConfigPage()),
        ChildRoute(path: '/orders', child: (_, _) => const OrdersPage()),
      ],
    ),
  ];
}
```

#### Shell Page

```dart
class PageWidget extends StatelessWidget {
  final Widget child;

  const PageWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.go('/user'),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.go('/config'),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => context.go('/orders'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

✅ Great for creating sub-navigation inside pages  
🎯 Useful for dashboards, admin panels, or multi-section UIs

### `StatefulShellModuleRoute`

StatefulShellModuleRoute is ideal for creating tab-based navigation with state preservation per tab — such as apps using BottomNavigationBar, TabBar, or any layout with parallel sections.

✅ Benefits

- Each tab has its own navigation stack.
- Switching tabs preserves their state and history.
- Seamless integration with Modugo modules, including guards and lifecycle.

🎯 Use Cases

- Bottom navigation with independent tabs (e.g. Home, Profile, Favorites)
- Admin panels or dashboards with persistent navigation
- Apps like Instagram, Twitter, or banking apps with separate stacked flows

💡 How it Works

Internally uses go_router's StatefulShellRoute to manage multiple Navigator branches. Each ModuleRoute below becomes an independent branch with its own routing stack.

```dart
StatefulShellModuleRoute(
  builder: (context, state, shell) => BottomBarWidget(shell: shell),
  routes: [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
    ModuleRoute(path: '/favorites', module: FavoritesModule()),
  ],
)
```

To keep module state across tabs:

```dart
final class ProfileModule extends Module {
  @override
  bool get persistent => true;
  ...
}
```

---

## 🔍 Route Matching with Regex

Modugo supports a powerful matching system using regex-based patterns. This allows you to:

- Validate paths and deep links before navigating
- Extract dynamic parameters independently of GoRouter
- Handle external URLs, web support, and custom redirect logic

### Defining a pattern:

```dart
ChildRoute(
  path: '/user/:id',
  routePattern: RoutePatternModel.from(r'^/user/(\d+)\$', paramNames: ['id']),
  child: (_, _) => const UserPage(),
)
```

### Matching a location:

```dart
final match = Modugo.matchRoute('/user/42');

if (match != null) {
  print(match.route); // matched route instance
  print(match.params); // { 'id': '42' }
} else {
  print('No match');
}
```

### Supported Route Types:

- `ChildRoute`
- `ModuleRoute`
- `ShellModuleRoute`
- `StatefulShellModuleRoute`

Useful for:

- Deep link validation
- Analytics and logging
- Fallback routing and redirects

---

## 🔄 Route Change Tracking

Modugo offers a built-in mechanism to track route changes globally via a `RouteNotifier`.
This is especially useful when you want to:

- Refresh parts of the UI when the location changes
- React to tab switches or deep links
- Trigger side effects like analytics or data reloading

---

### How it works

Modugo exposes a global `RouteNotifier` instance:

```dart
Modugo.routeNotifier // type: ValueNotifier<String>
```

This object emits a \[String] path whenever navigation occurs.
You can subscribe to it from anywhere:

```dart
Modugo.routeNotifier.addListener(() {
  final location = Modugo.routeNotifier.value;

  if (location == '/home') {
    refreshHomeWidgets();
  }
});
```

---

### Example Use Case

If your app uses dynamic tabs, webviews, or needs to react to specific navigation changes,
you can use the notifier to refresh content or trigger logic based on the current or previous route.

This is especially useful in cases like:

- Restoring scroll position
- Refreshing carousels
- Triggering custom analytics
- Resetting view state

---

### Automatic Integration

Modugo automatically uses `routeNotifier` as the default `refreshListenable` for GoRouter:

```dart
Modugo.configure(
  module: AppModule(),
  // You can override this, but if omitted:
  // → refreshListenable: Modugo.routeNotifier,
);
```

---

### Benefits

- ✅ Full visibility of route transitions
- 🧠 Provides rich context: previous/current/action
- 🔀 Enables reactive patterns beyond widget tree
- 🧰 Test-friendly and extensible

---

## ⚰️ Route Guards

You can protect routes using `IGuard`, which allows you to define redirection logic before a route is activated.

### 1. Define a guard

```dart
class AuthGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final auth = Modugo.get<AuthService>();
    return auth.isLoggedIn ? null : '/login';
  }
}
```

### 2. Apply to a route

```dart
ChildRoute(
  path: '/profile',
  guards: [AuthGuard()],
  child: (_, _) => const ProfilePage(),
)
```

Or:

```dart
ModuleRoute(
  path: '/admin',
  module: AdminModule(),
  guards: [AdminGuard()],
)
```

Guards are also supported inside `ShellModuleRoute` and `StatefulShellModuleRoute` branches:

```dart
StatefulShellModuleRoute(
  builder: (_, _, shell) => shell,
  routes: [
    ModuleRoute(path: '/account', module: AccountModule()),
    ModuleRoute(path: '/settings', module: SettingsModule(), guards: [SettingsGuard()]),
  ],
)
```

### ℹ️ Behavior

- If a guard returns a non-null path, navigation is redirected.
- Guards run **before** the route's `redirect` logic.
- Redirects are executed in order: **guards** ➔ **route.redirect** ➔ **child.redirect (if ModuleRoute)**
- Modugo never assumes where to redirect. It's up to you.

---

## 💊 Dependency Injection

### Supported Types

- `addSingleton<T>((i) => ...)`
- `addLazySingleton<T>((i) => ...)`
- `addFactory<T>((i) => ...)`

### Example

```dart
final class HomeModule extends Module {
  @override
  void binds(IInjector i) {
    i
      ..addSingleton<HomeController>((i) => HomeController(i.get<Repository>()))
      ..addLazySingleton<Repository>((_) => RepositoryImpl())
      ..addFactory<DateTime>((_) => DateTime.now());
  }

  @override
  List<IModule> get routes => [
    ChildRoute(path: '/home', child: (context, state) => const HomePage()),
  ];
}
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

## 🤝 Contributions

Pull requests, suggestions, and improvements are welcome!

---

## ⚙️ License

MIT ©
