## 1. Testes de dispose callback

- [x] 1.1 Criar `test/dispose/dispose_callback_test.dart` — testar `dispose:` callback em `registerSingleton` e `registerLazySingleton`
- [x] 1.2 Testar que `dispose:` callback é chamado no `unregister()`
- [x] 1.3 Testar que `dispose:` callback é chamado no `reset()`
- [x] 1.4 Testar que `dispose:` callback NÃO é chamado sem invocação explícita

## 2. Testes de interface Disposable

- [x] 2.1 Criar `test/dispose/disposable_interface_test.dart` — testar que GetIt chama `onDispose()` automaticamente no `reset()`
- [x] 2.2 Testar que `onDispose()` é chamado no `popScope()` para instâncias do scope

## 3. Testes de scopes

- [x] 3.1 Criar `test/dispose/scopes_test.dart` — testar `pushNewScope()`/`popScope()` com dispose
- [x] 3.2 Testar que scope filho sobrescreve registro do pai
- [x] 3.3 Testar que `popScope()` restaura registro do scope anterior

## 4. Testes de unregister individual

- [x] 4.1 Criar `test/dispose/unregister_test.dart` — testar `unregister()` com `disposingFunction`
- [x] 4.2 Testar que `disposingFunction` sobrescreve callback original

## 5. Testes de ordem de cleanup IEvent + GetIt

- [x] 5.1 Criar `test/dispose/ievent_cleanup_order_test.dart` — testar cleanup na ordem correta (IEvent.dispose antes de unregister)
- [x] 5.2 Testar padrão de reset global (`Event.i.disposeAll()` antes de `i.reset()`)

## 6. Validação

- [x] 6.1 Rodar `dart format --set-exit-if-changed lib test`
- [x] 6.2 Rodar `flutter analyze`
- [x] 6.3 Rodar `flutter test`

## 7. Atualizar documentação

- [x] 7.1 Atualizar spec `openspec/specs/injection/spec.md` aplicando delta
- [x] 7.2 Atualizar spec `openspec/specs/events/spec.md` aplicando delta
- [x] 7.3 Atualizar skill `.claude/skills/modugo/SKILL.md` com padrões de dispose
