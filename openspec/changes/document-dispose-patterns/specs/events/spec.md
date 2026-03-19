## ADDED Requirements

### Requirement: Ordem de cleanup — IEvent antes de unregister

Quando um módulo com `IEvent` precisa de cleanup completo, o Modugo DEVE
documentar que a ordem correta é:

1. `module.dispose()` — cancela event subscriptions (IEvent)
2. `i.unregister<T>()` ou `i.reset()` — remove binds (GetIt chama dispose callbacks)

Se a ordem for invertida, event listeners ativos podem tentar acessar
serviços já removidos do GetIt, causando erros em runtime.

```dart
// CORRETO
analyticsModule.dispose(); // cancela listeners primeiro
i.unregister<AnalyticsService>(); // depois remove o serviço

// ERRADO — pode causar erro se listener usa AnalyticsService
i.unregister<AnalyticsService>();
analyticsModule.dispose();
```

#### Scenario: cleanup na ordem correta

- **WHEN** um módulo com `IEvent` possui listeners que dependem de serviços registrados
- **WHEN** `module.dispose()` é chamado antes de `i.unregister<T>()`
- **THEN** os listeners DEVEM ser cancelados sem erros
- **THEN** os serviços DEVEM ser removidos com seus dispose callbacks executados

#### Scenario: cleanup na ordem errada pode causar erro

- **WHEN** um serviço é removido via `i.unregister<T>()` antes de `module.dispose()`
- **WHEN** um event listener ativo tenta acessar o serviço removido
- **THEN** o acesso ao serviço DEVE falhar (serviço não registrado)

### Requirement: reset global com IEvent

Quando `i.reset()` é chamado (ex: em testes ou logout), todos os módulos
com `IEvent` DEVEM ter seus listeners cancelados previamente para evitar
listeners órfãos que tentam acessar serviços removidos.

```dart
// Padrão de logout/reset completo
void logout() async {
  // 1. Cancelar todos os event listeners globais
  Event.i.disposeAll();

  // 2. Resetar GetIt (chama dispose callbacks)
  await Modugo.i.reset();

  // 3. Limpar módulos registrados para permitir re-registro
  // (necessário chamar Modugo.resetForTesting() ou equivalente)
}
```

#### Scenario: reset completo sem listeners órfãos

- **WHEN** `Event.i.disposeAll()` é chamado antes de `i.reset()`
- **THEN** nenhum listener DEVE estar ativo quando os serviços forem removidos
- **THEN** `i.reset()` DEVE completar sem erros de serviços não encontrados
