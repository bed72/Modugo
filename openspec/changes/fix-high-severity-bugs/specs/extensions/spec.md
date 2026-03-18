## MODIFIED Requirements

### Requirement: getExtra safe cast
`GoRouterStateExtension.getExtra<T>()` SHALL return `null` when `extra` is
non-null but of the wrong type, instead of throwing a `TypeError`.

#### Scenario: getExtra returns null for type mismatch
- **WHEN** `state.extra` is a non-null value of type `int`
- **WHEN** `state.getExtra<String>()` is called
- **THEN** the result SHALL be `null` (not a `TypeError`)

#### Scenario: getExtra returns value for type match
- **WHEN** `state.extra` is a `String`
- **WHEN** `state.getExtra<String>()` is called
- **THEN** the result SHALL be the String value

#### Scenario: getExtra returns null for null extra
- **WHEN** `state.extra` is `null`
- **THEN** `state.getExtra<T>()` SHALL return `null` for any `T`
