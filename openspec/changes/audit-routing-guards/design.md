## Context

Seis problemas independentes, todos localizados. Nenhum requer mudança arquitetural — são fixes
cirúrgicos com impacto mínimo. O maior cuidado é garantir que `_routesConfigured` por instância
não quebre o `resetRegistrations()` do módulo, e que `ShellModuleRoute.guards` seja
backward-compatible com todos os construtores existentes.

## Goals / Non-Goals

**Goals:**
- Eliminar os 6 problemas sem introduzir breaking changes
- Cada fix acompanhado de testes que provam o comportamento corrigido

**Non-Goals:**
- Refatorar a arquitetura de guards ou a estrutura de módulos
- Busca recursiva de ChildRoute em AliasRoute (escopo muito maior, considerado para v5)
- Modificar `StatefulShellModuleRoute` para aceitar `guards` próprios (análogo ao issue 12,
  mas fora do escopo desta mudança)

## Decisions

### D1: `_routesConfigured` por instância, não por Type

**Escolhido:** flag `bool _routesConfigured = false` como campo de instância em `Module`.

**Alternativa:** usar identidade em um `Set<Module>` no nível global, similar a `_modulesRegistered`.

**Rationale:** flag de instância é mais simples, sem coordenação global, e o `resetRegistrations()`
existente reseta `_modulesRegistered` mas não precisa resetar o flag de instância (pois a instância
em si é descartada junto com o módulo após reset).

**Trade-off:** se a mesma instância for reutilizada após `resetRegistrations()`, `configureRoutes()`
não re-executaria `_configureBinders()`. Aceitável: após reset, espera-se criar novas instâncias.

### D2: `Logger.warn` para módulo skipped, não exception

**Escolhido:** warning em vez de exception para módulo com mesmo `runtimeType`.

**Rationale:** lançar exception quebraria apps que genuinamente usam o mesmo módulo (sem estado
diferente) em múltiplos contextos. Warning é observável em dev sem impactar produção.

### D3: `ShellModuleRoute.guards` com `const []` default, `redirect` condicional

**Escolhido:** `redirect: guards.isNotEmpty ? (ctx, st) => _executeGuards(...) : null`.

**Rationale:** `null` explícito evita overhead de criar closure quando não há guards, mantendo
comportamento idêntico para `ShellModuleRoute` sem guards.

### D4: `AliasRoute` em `withInjectedGuards` — retornar `route` sem modificação

**Escolhido:** no case de `AliasRoute`, retornar `route` inalterado (guards são herdados da
rota alvo pelo `_createAlias`).

**Rationale:** `AliasRoute` não tem campo `guards` próprio — os guards são os da rota alvo.
Propagar guards herdados seria complexo e requer mudança na semântica de `AliasRoute`. O fix
aqui é apenas evitar que a rota seja descartada pelo `map` (o `return route` no else já faz isso,
mas de forma implícita; tornar explícito melhora legibilidade).

## Risks / Trade-offs

- **`_routesConfigured` não é resetado pelo `resetForTesting()`** → Se testes reutilizarem a
  mesma instância de módulo após `resetForTesting()`, `configureRoutes()` não re-executará.
  Mitigado: testes devem criar novas instâncias após reset (padrão já adotado nos testes atuais).

- **`ShellModuleRoute` com `guards` muda hashCode/equality** → `guards` não é incluído em
  `hashCode`/`==` para evitar complexidade; guards não participam de comparação estrutural.

## Migration Plan

Sem breaking changes. Todos os campos novos têm defaults que preservam comportamento anterior.

## Open Questions

Nenhuma.
