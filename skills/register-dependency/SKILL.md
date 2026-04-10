---
name: register-dependency
description: Register and access dependencies in Modugo modules using GetIt via the binds() method
---

# Register a Dependency in Modugo

Dependencies are registered in the `binds()` method of a module using `i` (the GetIt instance).

## Registration methods

```dart
@override
void binds() {
  // New instance every time get<T>() is called
  i.registerFactory<MyRepository>(() => MyRepositoryImpl());

  // Single instance for the entire app lifetime
  i.registerSingleton<AuthService>(AuthService());

  // Single instance, created on first use
  i.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Async singleton (e.g. needs await to initialize)
  i.registerSingletonAsync<Database>(() async {
    final db = Database();
    await db.init();
    return db;
  });
}
```

## Injecting dependencies

Pass them via constructor — `i.get<T>()` resolves the dependency:

```dart
i.registerFactory<ProfileViewModel>(
  () => ProfileViewModel(i.get<ProfileRepository>()),
);
```

## Accessing dependencies

Three equivalent ways:

```dart
// In any Dart code
final service = i.get<AuthService>();
final service = Modugo.i.get<AuthService>();

// Inside a widget (requires BuildContext)
final service = context.read<AuthService>();
```

## Shared dependencies via imports()

To reuse binds from another module without re-registering:

```dart
final class ProfileModule extends Module {
  @override
  List<Type> imports() => [CoreModule]; // shares CoreModule's binds

  @override
  void binds() {
    // CoreModule's binds are already available via i.get<T>()
    i.registerFactory<ProfileViewModel>(() => ProfileViewModel(i.get()));
  }
}
```

## Notes

- All binds live for the entire app lifetime — Modugo does not auto-dispose on navigation
- Prefer `registerFactory` for ViewModels/Controllers and `registerLazySingleton` for services
- Use `registerSingletonAsync` for dependencies that require async initialization (e.g. databases, shared preferences)

## Related context

Modugo's DI is powered by GetIt. For advanced registration patterns (scopes, named instances, async ready-check), consult GetIt docs directly:

```
use context7 with /fluttercommunity/get_it for advanced DI patterns
```
