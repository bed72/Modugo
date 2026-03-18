## ADDED Requirements

### Requirement: ShellModuleRoute builder null check
`FactoryRoute._createShell` SHALL throw `ArgumentError` with a clear message
when `ShellModuleRoute.builder` is `null` at configuration time.

#### Scenario: null builder throws ArgumentError
- **WHEN** `ShellModuleRoute(routes: [...], builder: null)` is compiled by `FactoryRoute`
- **THEN** an `ArgumentError` SHALL be thrown before any navigation occurs

---

### Requirement: ChildRoute.onExit forwarded to GoRoute
`FactoryRoute._createChild` SHALL pass `ChildRoute.onExit` to the underlying
`GoRoute.onExit` parameter.

#### Scenario: onExit is invoked during back navigation
- **WHEN** a `ChildRoute` has an `onExit` callback
- **WHEN** the user attempts to navigate back from that route
- **THEN** `onExit` SHALL be called with the current `BuildContext` and `GoRouterState`

#### Scenario: onExit returning false blocks navigation
- **WHEN** `onExit` returns `false`
- **THEN** the navigation SHALL be blocked

---

### Requirement: StatefulShellModuleRoute key preserved through guard injection
`StatefulShellModuleRoute.withInjectedGuards()` SHALL copy all fields including
`key` to the new instance.

#### Scenario: key is preserved after withInjectedGuards
- **WHEN** a `StatefulShellModuleRoute` is created with a `GlobalKey`
- **WHEN** `withInjectedGuards(guards)` is called
- **THEN** the resulting route SHALL have the same `key` instance

---

## MODIFIED Requirements

### Requirement: Route model hashCode contract
`ChildRoute`, `ModuleRoute`, and `ShellModuleRoute` SHALL satisfy:
`a == b` implies `a.hashCode == b.hashCode`.

`hashCode` SHALL include all fields used in `operator==`, including `runtimeType`.

#### Scenario: equal routes have equal hashCode
- **WHEN** two routes are equal by `operator==`
- **THEN** their `hashCode` values SHALL be equal
