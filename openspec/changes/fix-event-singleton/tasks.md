## 1. Implementação

- [ ] 1.1 Alterar `event.dart:7`: substituir `final Event events = Event._()` por `Event get events => Event.i`

## 2. Testes

- [ ] 2.1 Atualizar `test/events/event_singleton_test.dart`:
  remover o teste `[BUG-11] top-level events and Event.i are different instances`
  e adicionar: `events e Event.i são a mesma instância`
- [ ] 2.2 Adicionar teste: listener em `events.on<T>()` recebe evento de `Event.emit<T>()`

## 3. CI

- [ ] 3.1 Rodar `flutter test` — 0 falhas
- [ ] 3.2 Rodar `flutter analyze` — 0 issues
