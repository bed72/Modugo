## Context

O `Module` possui dois métodos — `initState()` e `dispose()` — que se apresentam
como hooks de ciclo de vida automático, mas nenhum ponto do framework os invoca.
O `IEvent` mixin faz override de ambos para registrar listeners e cancelar
subscriptions, porém como o framework nunca chama `initState()`, os listeners
nunca são ativados automaticamente. A situação cria API enganosa e funcionalidade
morta.

Arquivos diretamente afetados:
- `lib/src/module.dart` — define `initState()`, `dispose()`, `_configureBinders()`
- `lib/src/mixins/event_mixin.dart` — faz override de ambos
- `test/mixins/event_mixin_test.dart` — chama `initState()`/`dispose()` manualmente
- `test/mixins/event_mixin_auto_dispose_test.dart` — chama `dispose()` manualmente

## Goals / Non-Goals

**Goals:**
- Remover `initState()` e `dispose()` de `Module`, eliminando API falsa
- Fazer `IEvent.listen()` ser chamado automaticamente pelo framework de forma real
- Manter `IEvent.dispose()` como método próprio do mixin para cancelar subscriptions
- Atualizar specs, testes e documentação

**Non-Goals:**
- Implementar lifecycle completo de módulo (mount/unmount baseado em navegação)
- Alterar o sistema de eventos (`Event` singleton) em si
- Resolver DESIGN-14 (`on<T>(autoDispose: false)` sem retorno do `StreamSubscription`)

## Decisions

### D1: Ativação de `IEvent.listen()` via `_configureBinders()`

**Decisão:** Após registrar `binds()` de um módulo em `_configureBinders()`,
verificar se `targetBinder is IEvent` e chamar `listen()`.

**Rationale:**
- É o momento correto no ciclo de vida — binds já estão registrados, listeners
  podem depender de serviços injetados
- Mantém a invocação automática (sem esforço do usuário)
- Respeita a idempotência — como `_configureBinders` roda apenas uma vez por
  tipo de módulo, `listen()` também executa apenas uma vez

**Alternativa descartada:** Chamar `listen()` lazy na primeira invocação de `on()`.
Rejeitado porque `listen()` pode conter lógica além de `on()`, e o ponto de
ativação ficaria imprevisível.

### D2: `IEvent.dispose()` como método próprio (não override)

**Decisão:** `IEvent.dispose()` permanece como método do mixin, mas sem
`@override` e sem `super.dispose()`. Ele cancela subscriptions e limpa a lista.

**Rationale:**
- Mantém familiaridade com devs Flutter (nome `dispose()`)
- Sem `Module.dispose()` para fazer override, o método é definição nova do mixin
- O `IEvent` mixin é `on Module`, então `dispose()` será acessível na classe final

### D3: Remoção limpa de `Module.initState()` e `Module.dispose()`

**Decisão:** Remover os dois métodos e todas as docstrings associadas.

**Rationale:**
- Nunca foram chamados pelo framework
- A doc prometia comportamento automático que não existia
- Qualquer consumidor que fazia override não estava obtendo o efeito esperado

## Risks / Trade-offs

- **[Breaking change]** → Mitigação: módulos que fazem override de `initState()`
  ou `dispose()` terão erro de compilação. Na prática o impacto é desprezível pois
  esses overrides nunca tinham efeito. A migração é remover o override.

- **[IEvent agora ativa listen() automaticamente]** → Mitigação: antes `listen()`
  nunca era chamado (a menos que manualmente). Agora será chamado de verdade
  durante `configureRoutes()`. Se algum listener tinha side effect indesejado,
  ele passará a ocorrer. Consideramos isso uma correção, não uma regressão.

- **[IEvent.dispose() não é chamado automaticamente]** → Isso já era o
  comportamento real. A documentação será corrigida para refletir isso
  explicitamente.
