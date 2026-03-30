## Context

O sistema de guards do Modugo executa uma lista de `IGuard` de forma sequencial dentro do callback
`redirect` do GoRouter. Como esse callback é `async`, múltiplas instâncias de `_executeGuards` podem
ficar em voo simultaneamente quando o usuário (ou o próprio app) dispara navegações em sequência
rápida. Não existe hoje nenhum mecanismo que descarte o resultado de uma navegação supersedida.

O pacote `async` (pub.dev) oferece `CancelableOperation`, que envolve um `Future` e expõe um método
`cancel()` que impede a entrega do resultado sem cancelar o trabalho subjacente.

## Goals / Non-Goals

**Goals:**
- Garantir que o resultado de uma execução de guards supersedida seja descartado antes de ser
  entregue ao GoRouter
- Zero mudança na API pública (`IGuard`, `propagateGuards`, DSL de rotas)
- Cobertura de testes ampla do novo comportamento de concorrência

**Non-Goals:**
- Cancelar o trabalho async interno do guard (chamadas HTTP, DB) — isso é responsabilidade do guard
- Serializar navegações (fila) — apenas descartar resultados obsoletos
- Adicionar timeout à execução de guards
- Alterar o comportamento de guards síncronos

## Decisions

### D1: Usar `CancelableOperation` em vez de version counter

**Escolhido:** `CancelableOperation` do pacote `async`

**Alternativa considerada:** Version counter estático (`static int _guardVersion`)

**Rationale:** `CancelableOperation` expressa a intenção de forma explícita e oferece uma API
semanticamente correta para o problema. A semântica de `cancel()` + `valueOrCancellation(null)` é
autoexplicativa em code review. O version counter é mais low-level e exige comentário inline para
ser compreendido.

**Trade-off:** Nova dependência de produção (`async: ^2.12.0`). O pacote `async` é mantido pelo
Dart team (pub.dev: dart-lang/async), amplamente adotado no ecossistema Flutter, e tem zero
sub-dependências — o risco é mínimo.

### D2: Campo estático em `FactoryRoute`

**Escolhido:** `static CancelableOperation<String?>? _pendingGuards` em `FactoryRoute`

**Alternativa considerada:** Mapa por path (`Map<String, CancelableOperation>`)

**Rationale:** Um único campo estático é suficiente porque GoRouter processa os redirects de uma
navegação de forma sequencial (awaita cada um antes de chamar o próximo). Portanto, dentro de uma
mesma navegação, as chamadas a `_executeGuards` nunca se sobrepõem. O campo é incrementado apenas
quando uma nova navegação genuinamente supersede a anterior.

### D3: Extrair `_runGuards` como método interno

**Escolhido:** Separar o loop de guards em `_runGuards({required context, required guards, required state})`

**Rationale:** `CancelableOperation.fromFuture` precisa envolver um `Future` já iniciado. Extrair
`_runGuards` mantém `_executeGuards` limpo (responsabilidade única: gestão do ciclo de vida da
operação) e `_runGuards` testável de forma isolada.

### D4: `valueOrCancellation(null)` como valor de cancelamento

**Escolhido:** Retornar `null` quando cancelado

**Rationale:** `null` no contrato de `IGuard` significa "permite a navegação". Retornar `null`
ao cancelar é seguro: a nova navegação em curso irá executar seus próprios guards e decidir
se permite ou redireciona. O alternativo seria lançar uma exceção, mas isso interromperia
o GoRouter desnecessariamente.

## Risks / Trade-offs

- **Guards com side-effects ainda executam até o fim** → Aceitável. Não cancelar o trabalho
  interno é intencional (ver Non-Goals). Guards de analytics/logging funcionam corretamente.
  Guards que mutam estado compartilhado devem ser projetados para ser idempotentes — isso está
  fora do escopo desta mudança.

- **Campo estático compartilhado entre todos os redirects** → Mitigado pela garantia de
  sequencialidade interna do GoRouter (D2). Em testes, o campo deve ser resetado entre casos
  para evitar vazamento de estado (`FactoryRoute._pendingGuards = null` via `@visibleForTesting`
  ou reset implícito a cada chamada).

- **Dependência nova em produção** → Mitigado pela escolha do pacote `async` (dart-lang, zero
  sub-dependências, amplamente auditado).

## Migration Plan

Sem breaking changes — mudança é interna a `FactoryRoute`. Nenhuma ação necessária para
consumidores da lib.

## Open Questions

- Nenhuma.
