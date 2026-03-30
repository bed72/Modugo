## Context

`IEvent.on<T>()` atualmente retorna `void`. A `StreamSubscription` criada internamente só é
armazenada em `_subscriptions` se `autoDispose: true`. Com `autoDispose: false`, a subscription
é criada e imediatamente descartada — sem referência, sem forma de cancelar. O compilador Dart
não avisa porque void é um retorno válido para funções side-effect.

A mudança é cirúrgica: alterar o tipo de retorno de `void` para `StreamSubscription<T>`. Como
Dart permite ignorar valores de retorno, todos os call sites existentes continuam funcionando
sem modificação.

## Goals / Non-Goals

**Goals:**
- Eliminar o resource leak de `autoDispose: false`
- Manter compatibilidade total com call sites existentes (sem breaking change observável)
- Documentar ordem de cleanup IEvent → GetIt na API pública

**Non-Goals:**
- Alterar a semântica de `autoDispose: true` — comportamento permanece idêntico
- Mudar o design de `Event.i.on<T>()` (classe `Event`, não `IEvent` mixin) — escopo separado
- Forçar cleanup automático no `dispose()` de subscriptions `autoDispose: false`

## Decisions

### D1: Retornar `StreamSubscription<T>` em vez de guardar internamente com `autoDispose: false`

**Escolhido:** retornar a subscription e deixar o caller gerenciá-la.

**Alternativa considerada:** guardar em `_subscriptions` mas com flag "manual", expondo
`cancelManual(sub)` para remoção pontual.

**Rationale:** delegar ao caller é mais simples, mais idiomático em Dart (padrão do `Stream.listen`)
e não adiciona complexidade ao `_subscriptions` list. O caller que precisa de `autoDispose: false`
já demonstra intenção de gerenciamento manual.

### D2: Não forçar aviso de compilação para quem ignora o retorno

**Escolhido:** não usar `@useResult` ou similar.

**Rationale:** muitos usos de `autoDispose: true` dentro de `listen()` já ignoram o retorno
intencionalmente (o dispose automático é suficiente). Adicionar `@useResult` quebraria esses
call sites com warnings. A correção do DESIGN-14 já é o benefício; o aviso seria ruído.

### D3: `Logger.warn` se dispose() chamado sem registros GetIt ativos

**Escolhido:** adicionar warning quando `dispose()` é chamado e GetIt já foi resetado.

**Rationale:** ajuda a detectar ordem incorreta de cleanup em desenvolvimento sem adicionar
restrições em produção. O warning é suprimido quando `debugLogDiagnostics` é false.

## Risks / Trade-offs

- **Subscriptions `autoDispose: false` sem armazenamento pelo caller continuam vazando** →
  Aceitável: o DESIGN-14 original é que não havia forma alguma de cancelar. Agora há. O caller
  que ignora o retorno faz uma escolha explícita.

- **Warning do GetIt pode gerar falsos positivos** → Mitigado: o warning só aparece se
  `debugLogDiagnostics: true` (opt-in de desenvolvimento).

## Migration Plan

Sem breaking changes observáveis. Callers existentes compilam sem alteração.

## Open Questions

Nenhuma.
