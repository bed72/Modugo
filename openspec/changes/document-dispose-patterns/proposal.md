## Why

O GetIt oferece nativamente mecanismos robustos para dispose de dependências —
`dispose:` callback, interface `Disposable`, scopes hierárquicos, `unregister()`,
`reset()` — mas o Modugo não documenta, não exemplifica e não testa nenhum desses
padrões. O usuário que precisa fazer cleanup de recursos (fechar connections,
cancelar streams, liberar controllers) não sabe que essas ferramentas existem nem
como usá-las corretamente em conjunto com o sistema de módulos e eventos do Modugo.

## What Changes

- Documentar os padrões de dispose do GetIt na spec de `injection` do Modugo
- Documentar a interação correta entre `IEvent.dispose()` e cleanup de binds
- Criar testes que exercitam os use cases de dispose: `dispose:` callback,
  `Disposable` interface, scopes com `pushNewScope`/`popScope`, e `unregister()`
- Atualizar a spec de `events` com o padrão correto de ordem de cleanup
- Atualizar a skill do Modugo com os padrões documentados

## Capabilities

### New Capabilities

_(nenhuma — esta mudança documenta e testa capacidades já existentes no GetIt)_

### Modified Capabilities

- `injection`: Adicionar requisitos de documentação e padrões de dispose
  (`dispose:` callback, `Disposable`, scopes, `unregister`, `reset`)
- `events`: Documentar a ordem correta de cleanup quando `IEvent` coexiste
  com binds que possuem dispose callbacks

## Impact

- **Código**: Nenhuma mudança no código de produção do Modugo
- **Testes**: Novos arquivos de teste documentando os padrões de dispose
- **Specs**: `openspec/specs/injection/spec.md`, `openspec/specs/events/spec.md`
- **Skill**: `.claude/skills/modugo/SKILL.md`
- **Breaking changes**: Nenhum
