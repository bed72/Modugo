## MODIFIED Requirements

### Requirement: Single Event instance (replaces BUG-11 behavior)
The system SHALL guarantee that exactly one `Event` instance exists. The top-level
`events` variable and `Event.i` SHALL refer to the same object.

#### Scenario: events and Event.i are the same instance
- **WHEN** `events` and `Event.i` are accessed
- **THEN** `identical(events, Event.i)` SHALL be `true`

#### Scenario: listener on events receives emit from Event.emit
- **WHEN** `events.on<T>(callback)` is registered
- **WHEN** `Event.emit(T())` is called
- **THEN** `callback` SHALL be invoked
