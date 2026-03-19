## REMOVED Requirements

### Requirement: Ciclo de vida

**Reason**: `initState()` e `dispose()` nunca foram chamados automaticamente pelo
framework. A documentação afirmava comportamento automático que não existia,
criando API enganosa. O único consumidor (`IEvent`) será refatorado para não
depender desses hooks.

**Migration**: Remover qualquer override de `initState()` ou `dispose()` em
subclasses de `Module`. Se usava `IEvent`, `listen()` agora é chamado
automaticamente via `_configureBinders()`. Para cleanup, chamar
`moduleInstance.dispose()` diretamente no `IEvent`.

## MODIFIED Requirements

### CAP-MOD-03: Ciclo de vida

O módulo NÃO DEVE expor hooks genéricos de ciclo de vida (`initState`/`dispose`).

O ciclo de vida do módulo se resume a:

| Método | Quando | Chamado automaticamente |
|---|---|---|
| `binds()` | Primeira vez que o módulo é registrado | Sim |

Mixins como `IEvent` PODEM adicionar métodos de ciclo de vida específicos à sua
responsabilidade (ex: `listen()`, `dispose()`), mas estes pertencem ao mixin, não
ao `Module` base.

#### Scenario: Module não possui initState nem dispose

- **WHEN** um desenvolvedor cria uma subclasse de `Module`
- **THEN** os únicos métodos de ciclo de vida disponíveis são `binds()`, `imports()` e `routes()`
- **THEN** NÃO DEVE existir `initState()` nem `dispose()` na classe base `Module`

#### Scenario: Mixin adiciona lifecycle próprio

- **WHEN** um módulo aplica `IEvent` mixin
- **THEN** o mixin PODE definir seus próprios métodos (`listen()`, `dispose()`)
- **THEN** esses métodos pertencem ao mixin, não ao `Module` base
