---
name: create-route
description: Create routes in Modugo using ChildRoute, ModuleRoute, ShellModuleRoute, StatefulShellModuleRoute, or AliasRoute
---

# Create a Route in Modugo

Modugo has 5 route types. Always use the declarative DSL functions instead of instantiating the classes directly.

## Route types

| DSL function | Class | Use case |
|---|---|---|
| `child()` | `ChildRoute` | Regular page route |
| `module()` | `ModuleRoute` | Nested module |
| `shell()` | `ShellModuleRoute` | Shared layout (e.g. bottom nav) |
| `statefulShell()` | `StatefulShellModuleRoute` | Stateful shell with independent stacks |
| `alias()` | `AliasRoute` | Redirect/alias to another route |

## ChildRoute

```dart
child(
  '/home',
  builder: (context, state) => const HomePage(),
  guards: [AuthGuard()],
  transition: TypeTransition.fadeIn,
)
```

## ModuleRoute

```dart
module(
  '/profile',
  ProfileModule(),
  guards: [AuthGuard()], // propagates to all routes in ProfileModule
)
```

## ShellModuleRoute (shared scaffold)

```dart
shell(
  '/',
  builder: (context, state, child) => ScaffoldWithNavBar(child: child),
  module: ShellModule(),
)
```

## StatefulShellModuleRoute (independent tab stacks)

```dart
statefulShell(
  '/',
  builder: (context, state, shell) => NavBarPage(shell: shell),
  branches: [
    StatefulShellBranch(routes: [HomeModule().buildRoutes()]),
    StatefulShellBranch(routes: [ProfileModule().buildRoutes()]),
  ],
)
```

## AliasRoute

```dart
alias('/old-path', redirectTo: '/new-path')
```

## Notes

- Guards on `module()` and `shell()` propagate automatically to all child routes
- Use `TypeTransition` to set per-route transitions; the default is set in `Modugo.configure()`
- Access route parameters via `state.pathParameters` or `state.uri.queryParameters`

## Related context

Modugo routes are built on GoRouter. For advanced routing patterns (redirect, deep linking, extra codec), consult GoRouter docs directly:

```
use context7 with /websites/pub_dev_go_router for advanced routing patterns
```
