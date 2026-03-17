## ADDED Requirements

### Requirement: TypeTransition.native selects platform page type
The system SHALL provide `TypeTransition.native` as an enum value that maps to
`CupertinoPage` on iOS and `MaterialPage` on Android/web/desktop, giving users
an explicit way to opt into the native platform transition.

#### Scenario: native on iOS returns CupertinoPage
- **WHEN** a `ChildRoute` is configured with `transition: TypeTransition.native`
- **WHEN** the target platform is iOS
- **THEN** `_transition()` SHALL return a `CupertinoPage`

#### Scenario: native on Android returns MaterialPage
- **WHEN** a `ChildRoute` is configured with `transition: TypeTransition.native`
- **WHEN** the target platform is Android
- **THEN** `_transition()` SHALL return a `MaterialPage`

#### Scenario: native on other platforms returns MaterialPage
- **WHEN** a `ChildRoute` is configured with `transition: TypeTransition.native`
- **WHEN** the target platform is neither iOS nor Android (e.g., web, desktop)
- **THEN** `_transition()` SHALL return a `MaterialPage`

---

### Requirement: Global iOS gesture navigation flag
The system SHALL expose `enableIOSGestureNavigation: bool` in `Modugo.configure()`
defaulting to `true`. When `true`, all routes without an explicit custom transition
on iOS SHALL use `CupertinoPage` to enable back-swipe gesture.

#### Scenario: default enables back swipe on iOS
- **WHEN** `Modugo.configure()` is called without `enableIOSGestureNavigation`
- **WHEN** a route has no explicit `transition`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CupertinoPage`

#### Scenario: global false keeps CustomTransitionPage on iOS
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: false)` is called
- **WHEN** a route has no explicit `transition`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CustomTransitionPage`

#### Scenario: global flag does not affect non-iOS platforms
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: true)` is called
- **WHEN** the platform is Android
- **THEN** `_transition()` SHALL return a `CustomTransitionPage`

---

### Requirement: Per-route iOS gesture override
`ChildRoute` SHALL expose `iosGestureEnabled: bool?` that overrides the global
`enableIOSGestureNavigation` for that specific route. `null` means inherit global.

#### Scenario: per-route true overrides global false
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: false)` is set
- **WHEN** a `ChildRoute` is declared with `iosGestureEnabled: true`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CupertinoPage` for that route

#### Scenario: per-route false overrides global true
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: true)` is set (default)
- **WHEN** a `ChildRoute` is declared with `iosGestureEnabled: false`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CustomTransitionPage` for that route

#### Scenario: per-route null inherits global
- **WHEN** a `ChildRoute` is declared without `iosGestureEnabled` (null)
- **THEN** the route SHALL inherit `Modugo.enableIOSGestureNavigation`

---

### Requirement: Explicit custom transition disables iOS gesture for that route
When a `ChildRoute` defines an explicit `transition` (any value other than `native`
or `null`), the system SHALL use `CustomTransitionPage` regardless of platform or
global setting, honoring the developer's intentional animation choice.

#### Scenario: explicit transition bypasses iOS gesture on iOS
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: true)` is set
- **WHEN** a `ChildRoute` has `transition: TypeTransition.fade`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CustomTransitionPage` with the fade animation

#### Scenario: explicit slideLeft transition bypasses iOS gesture
- **WHEN** a `ChildRoute` has `transition: TypeTransition.slideLeft`
- **WHEN** the platform is iOS
- **THEN** `_transition()` SHALL return a `CustomTransitionPage` with slideLeft animation

---

### Requirement: iosGestureEnabled exposed in IDsl child() method
The `IDsl.child()` method SHALL include `iosGestureEnabled: bool?` as an optional
parameter, forwarding it to `ChildRoute`.

#### Scenario: DSL propagates iosGestureEnabled to ChildRoute
- **WHEN** `child(path: '/x', child: ..., iosGestureEnabled: false)` is called
- **THEN** the resulting `ChildRoute` SHALL have `iosGestureEnabled == false`
