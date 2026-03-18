## MODIFIED Requirements

### Requirement: _configureBinders propagates errors synchronously
`Module._configureBinders()` SHALL be a synchronous method. Exceptions thrown
inside `binds()` or imported modules' `binds()` SHALL propagate to the caller
(`configureRoutes()`) synchronously, not be silently discarded.

#### Scenario: exception in binds() propagates to configureRoutes
- **WHEN** a module's `binds()` throws an exception
- **WHEN** `module.configureRoutes()` is called
- **THEN** the exception SHALL propagate out of `configureRoutes()`
- **THEN** the exception SHALL NOT be silently swallowed

#### Scenario: exception in imported module's binds() propagates
- **WHEN** an imported module's `binds()` throws
- **WHEN** the parent module's `configureRoutes()` is called
- **THEN** the exception SHALL propagate to the caller

#### Scenario: normal module registration is unchanged
- **WHEN** `binds()` does not throw
- **THEN** the module registration behavior SHALL be identical to before
