---
name: create-module
description: Create a new Modugo module with routes, binds, and imports
---

# Create a Modugo Module

A module in Modugo extends `Module` and implements three methods: `imports()`, `binds()`, and `routes()`.

## Steps

1. Create a class that extends `Module`
2. Declare dependencies in `binds()` using `i.register*`
3. Declare routes in `routes()` using the declarative DSL
4. Import sub-modules in `imports()` if needed

## Basic module

```dart
final class ProfileModule extends Module {
  @override
  List<Type> imports() => []; // shared modules to import

  @override
  void binds() {
    i.registerFactory<ProfileRepository>(() => ProfileRepositoryImpl());
    i.registerFactory<ProfileViewModel>(() => ProfileViewModel(i.get()));
  }

  @override
  List<IRoute> routes() => [
    child('/', builder: (_, _) => const ProfilePage()),
    child('/edit', builder: (_, _) => const EditProfilePage()),
  ];
}
```

## Module with guard

```dart
final class ProfileModule extends Module {
  @override
  void binds() {
    i.registerFactory<ProfileRepository>(() => ProfileRepositoryImpl());
  }

  @override
  List<IRoute> routes() => [
    child(
      '/',
      builder: (_, _) => const ProfilePage(),
      guards: [AuthGuard()],
    ),
  ];
}
```

## Registering the module in the parent

```dart
@override
List<IRoute> routes() => [
  child('/', builder: (_, _) => const HomePage()),
  module('/profile', ProfileModule()),
];
```

## Notes

- All binds registered in a module are available via `i.get<T>()`, `Modugo.i.get<T>()`, or `context.read<T>()`
- Guards defined on a `module()` route propagate automatically to all child routes
- Use `imports()` to share a module's binds with child modules without re-registering
