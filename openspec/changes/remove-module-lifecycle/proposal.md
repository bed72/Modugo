## Why

`Module.initState()` e `Module.dispose()` são declarados como hooks de ciclo de vida
e documentados como "chamados automaticamente pelo framework", mas **nenhum código no
Modugo os invoca**. `configureRoutes()` chama apenas `_configureBinders()` + `FactoryRoute.from()`.
Isso cria uma API enganosa: usuários podem fazer override esperando comportamento automático
que nunca ocorre. O mixin `IEvent` depende desses métodos para funcionar, mas como
ninguém os chama, `IEvent` também está quebrado na prática.

## What Changes

- **BREAKING**: Remover `initState()` e `dispose()` de `Module`
- Refatorar `IEvent` para chamar `listen()` automaticamente via `_configureBinders()` (após binds registrados)
- `IEvent.dispose()` passa a ser método próprio do mixin (não mais override de Module)
- Atualizar docstrings e specs afetadas

## Capabilities

### New Capabilities

_(nenhuma — esta mudança simplifica a API existente)_

### Modified Capabilities

- `module-system`: Remover CAP-MOD-03 (lifecycle hooks `initState`/`dispose`), atualizar tabela de ciclo de vida
- `events`: Atualizar CAP-EVT-05 (`IEvent`) — `listen()` agora chamado via `_configureBinders`, `dispose()` é método próprio do mixin

## Impact

- **Código**: `lib/src/module.dart`, `lib/src/mixins/event_mixin.dart`
- **Testes**: `test/mixins/event_mixin_test.dart`, `test/mixins/event_mixin_auto_dispose_test.dart`
- **Specs**: `openspec/specs/module-system/spec.md`, `openspec/specs/events/spec.md`
- **Skill**: `.claude/skills/modugo/SKILL.md`
- **Breaking change**: Consumidores que fazem override de `initState()` ou `dispose()` em Module terão erro de compilação. Na prática o impacto é mínimo pois esses métodos nunca eram chamados pelo framework.
