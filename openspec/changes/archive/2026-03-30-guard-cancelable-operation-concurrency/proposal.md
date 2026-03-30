## Why

Guards são `async`, mas `_executeGuards` não possui mecanismo de cancelamento: quando múltiplas
navegações são disparadas em sequência rápida (redirects encadeados, webviews, double-tap), múltiplas
instâncias ficam em voo simultaneamente e o resultado de uma navegação antiga pode ser aplicado pelo
GoRouter após uma navegação mais nova já ter sido iniciada.

## What Changes

- Adicionar `async: ^2.12.0` ao `pubspec.yaml` como dependência de produção
- Adicionar campo estático `_pendingGuards: CancelableOperation<String?>?` em `FactoryRoute`
- Modificar `_executeGuards` para cancelar a operação anterior e criar uma nova `CancelableOperation`
- Extrair o loop de guards para `_runGuards` (método interno puro, sem gestão de cancelamento)
- Retornar `operation.valueOrCancellation(null)` — `null` descarta o redirect, permitindo a nova navegação prosseguir
- Adicionar `test/guards/guard_concurrency_test.dart` com cobertura ampla do novo comportamento

## Capabilities

### New Capabilities

- `guard-concurrency-protection`: Proteção contra condições de corrida na execução de guards async via `CancelableOperation`, garantindo que apenas o resultado da navegação mais recente seja entregue ao GoRouter

### Modified Capabilities

- `guards`: A execução de guards (`_executeGuards`) passa a cancelar resultados pendentes de chamadas anteriores; o contrato público de `IGuard` e `propagateGuards` não muda

## Impact

- **`lib/src/routes/factory_route.dart`** — modificado (`_executeGuards`, novo `_runGuards`, novo campo estático)
- **`pubspec.yaml`** — nova dependência `async: ^2.12.0`
- **`test/guards/guard_concurrency_test.dart`** — novo arquivo de testes
- **API pública**: sem breaking changes — `IGuard`, `propagateGuards`, DSL de rotas permanecem idênticos
- **Comportamento observável**: em cenários de navegação concorrente, o resultado de uma chamada anterior a `_executeGuards` é descartado (retorna `null`) em vez de ser aplicado ao GoRouter
