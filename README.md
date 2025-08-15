<p align="center">
  <img src="https://raw.githubusercontent.com/bed72/Modugo/master/images/banner.png" alt="Modugo Logo" />
</p>

# Modugo

**Modugo** is a modular system for Flutter inspired by [Flutter Modular](https://pub.dev/packages/flutter_modular) and [Go Router Modular](https://pub.dev/packages/go_router_modular). It provides a clean structure to organize **modules, routes, and dependency injection**. It provides a clean way to structure your app into isolated modules, but **it does not manage dependency disposal**.

## Key Points

- Uses **GoRouter** for navigation between routes.
- Uses **GetIt** for dependency injection.
- Dependencies are registered **once at app startup** when modules are initialized.
- There is **no automatic disposal** of dependencies; once injected, they live for the lifetime of the application.
- Designed to provide **decoupled, modular architecture** without enforcing lifecycle management.
- Focuses on **clarity and structure** rather than automatic cleanup.

> ⚠️ Note: Unlike some modular frameworks, Modugo **does not automatically dispose dependencies** when routes are removed. All dependencies live until the app is terminated.  
> This is a **breaking change** from versions prior to 3.x, where automatic disposal of route-scoped dependencies was performed. If you are migrating from an older version (<3), be aware that you may need to manually manage dependency disposal.

---

## Features

- Integration with **GoRouter**
- Registration of **dependencies** with **GetIt**
- Support for **imported modules** (nested modules)
- Support for `ShellRoute` and `StatefulShellRoute`
- Detailed and configurable logging
- Built-in support for **Route Guards**
- Built-in support for **Regex-based Route Matching**

---

## Installation

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
    /chat
      chat_page.dart
      chat_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

---

## Getting Started

### main.dart

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(
      ModugoLoaderWidget(
        loading: const LoadWidget(), // Your loading widget
        builder: (_) => const AppWidget(),
        dependencies: [ /* List of asynchronous dependencies */ ],
      ),
  );
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
      title: 'Modugo App',
      routerConfig: Modugo.routerConfig,
    );
  }
}
```

---

### app_module.dart

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>((_) => AuthService());
  }

  @override
  List<IModule> routes() => [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/chat', module: ChatModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
  ];
}
```

---

## Logging and Diagnostics

```dart
Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,
);
```

- All logs pass through the `Logger` class, which can be extended or customized.
- Logs include injection, disposal, navigation, and errors.

---

## Navigation

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
  List<IModule> routes() => [
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

---

## Route Matching with Regex

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

## Event System in Modugo

Modugo provides a lightweight event system for modular, decoupled communication between components and modules using `EventBus`. This allows you to emit and listen to typed events in a safe and organized way.

### Core Concepts

- **defaultEvents**: A global `EventBus` used by the modular system if no custom bus is provided.
- **eventSubscriptions**: Tracks all active event subscriptions per `EventBus` and event type, allowing proper cleanup and automatic disposal.

### Setting Up Event Listeners

You can listen to events of a specific type using the `EventChannel` singleton or your module's `EventRegistry`:

```dart
class MyEvent {
  final String message;
  MyEvent(this.message);
}

// Listen to events globally
EventChannel.instance.on<MyEvent>((event) {
  print('Received event: ${event.message}');
});

// Emit an event
EventChannel.emit(MyEvent('Hello Modugo!'));
```

### Using a Custom EventBus

You can create and use a custom `EventBus` if you want isolated channels:

```dart
final customBus = EventBus();

EventChannel.instance.on<MyEvent>((event) {
  print('Custom bus event: ${event.message}');
}, eventBus: customBus);

EventChannel.emit(MyEvent('Custom hello!'), eventBus: customBus);
```

## Automatic Disposal

The system tracks subscriptions so that you can safely dispose individual listeners or all listeners:

```dart
// Dispose a specific listener
EventChannel.instance.dispose<MyEvent>();

// Dispose all listeners for a given EventBus
EventChannel.instance.disposeAll();
```

## Integration with EventRegistry

If you use mixin `EventRegistry`, in your module, can register listeners inside `listen()`:

```dart
class MyModule extends Module with EventRegistry {
  @override
  void listen() {
    on<MyEvent>((event) {
      print('Module received: ${event.message}');
    }, autoDispose: true);
  }
}
```

- `autoDispose: true` ensures that the subscription is automatically cancelled when the module is disposed.

## Summary

- Use `EventChannel` for global or module-scoped events.
- `defaultEvents` is the default bus for all modular events.
- `eventSubscriptions` tracks active subscriptions for safe disposal.
- Integrate `EventRegistry` to manage listeners automatically within module lifecycles.

---

## Route Guards

You can protect routes using `IGuard`, which allows you to define redirection logic before a route is activated.

### 1. Define a guard

```dart
class AuthGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final auth = context.read<AuthService>();
    return auth.isLoggedIn ? null : '/login';
  }
}
```

### 2. Apply to a single route

```dart
ChildRoute(
  path: '/profile',
  guards: [AuthGuard()],
  child: (_, _) => const ProfilePage(),
);
```

### 3. Propagate guards to nested routes

If you want a guard applied at a **parent module** level to automatically protect **all child routes** (even inside nested `ModuleRoute`s), you can use `propagateGuards`.

This is especially useful when you want consistent access control without having to manually add guards to each child route.

```dart
List<IModule> routes() => propagateGuards(
  guards: [AuthGuard()],
  routes: [
    ModuleRoute(
      path: '/',
      module: HomeModule(),
    ),
  ]
);
```

In the example above, `AuthGuard` will be automatically applied to all routes inside `HomeModule`, including nested `ChildRoute`s and `ModuleRoute`s, without needing to repeat it manually.

### Behavior

- If a guard returns a non-null path, navigation is redirected.
- Guards run **before** the route's `redirect` logic.
- Redirects are executed in order: **guards** ➔ **route.redirect** ➔ **child.redirect (if ModuleRoute)**
- Modugo never assumes where to redirect. It's up to you.

---

## Dependency Injection in Modugo

In Modugo, dependencies are registered using the `binds()` method inside a `Module`. You have access to `i`, which is a shorthand for `GetIt.instance`. You can register singletons, lazy singletons, or factories in a fluent API style similar to [GetIt](https://pub.dev/packages/get_it).

### Example

```dart
class HomeModule extends Module {
  @override
  List<Module> imports() => [CoreModule()];

  @override
  List<IModule> routes() => [
    ChildRoute(path: '/', child: (context, state) => const HomePage()),
  ];

  @override
  void binds() {
    i
      ..registerSingleton<ServiceRepository>(ServiceRepository.instance)
      ..registerLazySingleton<OtherServiceRepository>(OtherServiceRepositoryImpl.new);
  }
}
```

> All dependencies are registered at startup and remain alive for the full app lifecycle. They are **never automatically disposed**.

### Notes

- `registerSingleton<T>(...)` registers a singleton instance immediately.
- `registerLazySingleton<T>(...)` registers a singleton lazily, creating it only on first access.
- All registered dependencies are globally accessible via `i.get<T>()` or using Modugo’s `BuildContext` extension `context.read<T>()`.

---

## Contributions

Pull requests, suggestions, and improvements are welcome!

---

## License

MIT ©
