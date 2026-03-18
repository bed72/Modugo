## Why

Existe um objeto `events` (variável top-level em `event.dart:7`) e `Event.i`
(lazy singleton via `static Event get i`). Eles são **instâncias diferentes** —
cada uma tem seu próprio mapa `_controllers`. Código que registra listeners em
`events` nunca recebe os eventos emitidos via `Event.emit()` (que usa `Event.i`),
e vice-versa. Toda a API pública funciona, mas a comunicação entre módulos que
usam paths diferentes silenciosamente falha.

## What Changes

- Remover a variável top-level `events` ou torná-la um alias de `Event.i`
- Garantir que existe exatamente **uma** instância de `Event` em todo o processo
- Atualizar qualquer código que referencia `events` diretamente para usar `Event.i`
  ou `Event.emit`

## Capabilities

### New Capabilities
- Nenhuma

### Modified Capabilities

- `events`: comportamento do sistema de eventos unificado em uma única instância.

## Impact

**Arquivos modificados:**
- `lib/src/events/event.dart` — remover `final Event events = Event._()` ou
  tornar `events` um getter que retorna `Event.i`

**Risco de breaking change:**
- Se algum consumidor externo usa `events.on<T>(...)` diretamente (o que é
  improvável dado que a API pública expõe `Event.i`), haverá mudança de comportamento
  — mas o comportamento anterior era silenciosamente quebrado, então a correção é
  sempre preferível
