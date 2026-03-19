## MODIFIED Requirements

### CAP-EVT-05: IEvent mixin — integração com módulos

O mixin `IEvent` integra o event bus ao módulo com ativação automática e cleanup manual:

```dart
final class AnalyticsModule extends Module with IEvent {
  @override
  void listen() {
    on<UserLoggedInEvent>((event) {
      Analytics.trackLogin(event.userId);
    });

    on<RouteChangedEventModel>((event) {
      Analytics.trackPageView(event.location);
    });

    // autoDispose: false → vive além do módulo
    on<SystemEvent>((e) => handleSystem(e), autoDispose: false);
  }

  @override
  List<IRoute> routes() => [];
}
```

**Comportamento atualizado do IEvent:**
- `listen()` DEVE ser chamado automaticamente por `_configureBinders()` após os
  `binds()` do módulo serem registrados, quando o módulo implementa `IEvent`
- `listen()` NÃO DEVE depender de `Module.initState()` (que foi removido)
- `on<T>()` com `autoDispose: true` (padrão) → subscription cancelada no `dispose()`
- `on<T>()` com `autoDispose: false` → subscription persiste após o dispose do módulo
- `dispose()` é método próprio do `IEvent` mixin (não override de `Module`)
- `dispose()` NÃO é chamado automaticamente — é responsabilidade do consumidor

#### Scenario: listen() chamado automaticamente via _configureBinders

- **WHEN** um módulo com `IEvent` é configurado pela primeira vez
- **THEN** `_configureBinders()` DEVE detectar que o módulo implementa `IEvent`
- **THEN** `listen()` DEVE ser invocado automaticamente após `binds()` do módulo

#### Scenario: listen() só é chamado uma vez

- **WHEN** um módulo com `IEvent` é importado por múltiplos módulos
- **THEN** `listen()` DEVE ser invocado apenas uma vez (idempotência de `_configureBinders`)

#### Scenario: dispose() cancela subscriptions com autoDispose true

- **WHEN** `dispose()` é chamado no módulo com `IEvent`
- **THEN** todas as subscriptions registradas com `autoDispose: true` DEVEM ser canceladas
- **THEN** subscriptions com `autoDispose: false` NÃO DEVEM ser canceladas

#### Scenario: dispose() não é chamado automaticamente

- **WHEN** um módulo com `IEvent` é configurado
- **THEN** o framework NÃO DEVE chamar `dispose()` automaticamente
- **THEN** é responsabilidade do consumidor invocar `dispose()` quando necessário
