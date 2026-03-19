## Context

O Modugo usa GetIt como service locator. Todas as dependências registradas via
`binds()` são globais e vivem por toda a vida do app. O GetIt oferece nativamente
4 mecanismos de dispose que o Modugo não documenta nem testa:

1. **`dispose:` callback** — passado no registro, chamado em `unregister()`/`reset()`
2. **`Disposable` interface** — GetIt chama `onDispose()` automaticamente em reset/popScope
3. **Scopes** — `pushNewScope()`/`popScope()` para agrupar registros
4. **`unregister<T>()`** — remoção individual com callback opcional

O sistema de eventos (`IEvent`) possui seu próprio `dispose()` que cancela
subscriptions. Quando o desenvolvedor precisa fazer cleanup completo (ex: logout),
a ordem de operações entre `IEvent.dispose()` e `GetIt.unregister()` importa.

## Goals / Non-Goals

**Goals:**
- Documentar os 4 padrões de dispose do GetIt nas specs do Modugo
- Criar testes que exercitem cada padrão como documentação executável
- Documentar a ordem correta de cleanup quando IEvent coexiste com binds
- Atualizar a skill do Modugo com os padrões

**Non-Goals:**
- Criar abstrações ou wrappers sobre o GetIt (nenhum código novo em lib/)
- Implementar dispose automático de módulos
- Implementar tracking de binds por módulo
- Criar DSL para dispose

## Decisions

### D1: Testes como documentação primária

**Decisão:** Criar testes que demonstram cada padrão de dispose. Os testes são
a melhor documentação porque são executáveis e verificáveis.

**Estrutura dos testes:**
- `test/dispose/dispose_callback_test.dart` — `dispose:` no registro
- `test/dispose/disposable_interface_test.dart` — interface `Disposable`
- `test/dispose/scopes_test.dart` — `pushNewScope()`/`popScope()`
- `test/dispose/unregister_test.dart` — remoção individual
- `test/dispose/ievent_cleanup_order_test.dart` — IEvent + binds cleanup

### D2: Não modificar código de produção

**Decisão:** Zero mudanças em `lib/`. Apenas testes, specs e docs.

**Rationale:** O GetIt já oferece tudo que precisa. Adicionar wrappers ou
abstrações seria complexidade sem benefício real. O valor está em tornar
explícito o que hoje é obscuro.

### D3: Documentar a ordem de cleanup com IEvent

**Decisão:** Documentar que quando um módulo com `IEvent` precisa de cleanup
completo, a ordem DEVE ser:

1. `module.dispose()` — cancela event subscriptions (IEvent)
2. `i.unregister<T>()` — remove binds (GetIt chama dispose callbacks)

Se a ordem for invertida, um event listener pode tentar acessar um serviço
que já foi removido do GetIt → erro em runtime.

## Risks / Trade-offs

- **[Testes dependem de internals do GetIt]** → Mitigação: testes exercitam a
  API pública do GetIt que o Modugo já expõe. Não acessam internals.

- **[Desenvolvedor pode esperar dispose automático após ler a doc]** → Mitigação:
  docs explícitas de que dispose callbacks são chamados apenas em
  `unregister()`, `reset()`, ou `popScope()` — nunca automaticamente ao navegar.

- **[Scopes do GetIt são hierárquicos — edge cases]** → Mitigação: documentar
  claramente que scopes são um padrão avançado e que binds compartilhados
  (via `imports()`) devem estar no scope base, não em scopes filhos.
