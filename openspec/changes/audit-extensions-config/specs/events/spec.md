## MODIFIED Requirements

### Requirement: RouteChangedEventModel é emitido após microtask
`RouteChangedEventModel` SHALL ser emitido via `Future.microtask`, garantindo que listeners
recebam o evento após o ciclo de processamento atual do GoRouter, e não sincronamente dentro
do callback `addListener`.

#### Scenario: Evento chega após o microtask atual do listener
- **WHEN** GoRouter muda de rota e dispara o listener
- **THEN** `RouteChangedEventModel` NÃO é emitido sincronamente dentro do callback
- **THEN** `RouteChangedEventModel` é emitido no próximo microtask

#### Scenario: Evento ainda é emitido para cada mudança de rota única
- **WHEN** a rota muda de `/a` para `/b`
- **THEN** exatamente um `RouteChangedEventModel` é emitido com location `/b`

#### Scenario: Evento não é emitido quando location não muda
- **WHEN** o listener dispara mas `matchedLocation` é o mesmo que o último notificado
- **THEN** nenhum evento é emitido (deduplicação preservada)
