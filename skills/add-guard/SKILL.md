---
name: add-guard
description: Create and apply route guards in Modugo to protect routes with conditional logic
---

# Add a Guard in Modugo

Guards implement `IGuard` and decide whether navigation to a route should proceed or redirect.

## Create a guard

```dart
final class AuthGuard implements IGuard {
  @override
  FutureOr<String?> canActivate(BuildContext context, GoRouterState state) {
    final auth = Modugo.i.get<AuthService>();

    if (auth.isAuthenticated) return null; // allow navigation

    return '/login'; // redirect
  }
}
```

- Return `null` to allow navigation
- Return a route path (`String`) to redirect
- The method can be `async` (`Future<String?>`)

## Apply a guard to a route

```dart
child(
  '/dashboard',
  builder: (_, _) => const DashboardPage(),
  guards: [AuthGuard()],
)
```

## Apply a guard to an entire module

Guards on `module()` propagate automatically to every route inside the module.

```dart
module(
  '/admin',
  AdminModule(),
  guards: [AuthGuard(), AdminRoleGuard()],
)
```

## Multiple guards

Guards are evaluated in order. The first one that returns a non-null path stops the chain.

```dart
guards: [AuthGuard(), FeatureFlagGuard('admin-panel')]
```

## Guard with async logic

```dart
final class SessionGuard implements IGuard {
  @override
  Future<String?> canActivate(BuildContext context, GoRouterState state) async {
    final session = await Modugo.i.get<SessionService>().validate();

    return session.isValid ? null : '/session-expired';
  }
}
```

## Notes

- Guards receive the `BuildContext` and `GoRouterState` — access DI via `Modugo.i.get<T>()` or `context.read<T>()`
- Exceptions thrown inside `canActivate` are caught, logged, and rethrown — the navigation is blocked
- Propagation: a guard on a `module()` route applies to all `ChildRoute` descendants automatically
