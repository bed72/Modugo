## Context

`event.dart` declara:
```dart
final Event events = Event._();        // linha 7 — instância própria
static Event get i => _instance ??= Event._();  // linha 21 — outra instância
```

`Event.emit<T>()` usa `i._controllers[T]`. `events` tem seu próprio
`_controllers` vazio. Os dois nunca se comunicam.

## Goals / Non-Goals

**Goals:**
- Uma única instância de `Event` em todo o app
- `Event.emit` e `events.on`/`Event.i.on` atingem os mesmos listeners

**Non-Goals:**
- Mudar a API pública de `Event` além do necessário
- Suporte a múltiplos barramentos de evento

## Decisions

### D1: Tornar `events` um alias de `Event.i`

```dart
// Antes
final Event events = Event._();

// Depois
Event get events => Event.i;
```

Isso preserva a compatibilidade com código que usa `events.on<T>()` e elimina a
duplicação. A mudança de `final` para `getter` é transparente para os chamadores.

**Alternativa rejeitada:** remover `events` completamente — seria uma breaking
change desnecessária se alguém depende da variável top-level.

## Risks / Trade-offs

**[Mudança de comportamento]** → Qualquer código que dependia do isolamento acidental
das duas instâncias passará a compartilhar o mesmo estado. Isso é sempre o comportamento
correto, não uma regressão.

## Migration Plan

1. Substituir `final Event events = Event._()` por `Event get events => Event.i`
2. Rodar `flutter test` — o teste `event_singleton_test.dart` deve ser atualizado:
   o teste `[BUG-11] top-level events and Event.i are different instances` passa
   a falhar (o que confirma a correção) e deve ser removido ou invertido
