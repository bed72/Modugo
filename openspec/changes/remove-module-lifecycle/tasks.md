## 1. Refatorar IEvent mixin

- [x] 1.1 Remover `@override void initState()` de `IEvent` — `listen()` será chamado externamente por `_configureBinders()`
- [x] 1.2 Mudar `dispose()` para método próprio do mixin (sem `@override`, sem `super.dispose()`)
- [x] 1.3 Atualizar docstrings do `IEvent` para refletir novo comportamento

## 2. Integrar IEvent.listen() em _configureBinders

- [x] 2.1 Adicionar import de `event_mixin.dart` em `module.dart`
- [x] 2.2 Em `_configureBinders()`, após `binds()` + `_modulesRegistered.add()`, verificar `targetBinder is IEvent` e chamar `listen()`

## 3. Remover initState/dispose de Module

- [x] 3.1 Remover `void initState() {}` e toda sua docstring
- [x] 3.2 Remover `void dispose() {}` e toda sua docstring
- [x] 3.3 Atualizar docstring da classe `Module` removendo referências a `initState()`/`dispose()`

## 4. Atualizar testes

- [x] 4.1 Atualizar `test/mixins/event_mixin_test.dart` — substituir `module.initState()` por chamada direta a `listen()`
- [x] 4.2 Atualizar `test/mixins/event_mixin_auto_dispose_test.dart` se necessário

## 5. Validação

- [x] 5.1 Rodar `dart format --set-exit-if-changed lib test`
- [x] 5.2 Rodar `flutter analyze`
- [x] 5.3 Rodar `flutter test`

## 6. Atualizar documentação

- [x] 6.1 Atualizar spec `openspec/specs/module-system/spec.md` aplicando delta
- [x] 6.2 Atualizar spec `openspec/specs/events/spec.md` aplicando delta
- [x] 6.3 Atualizar skill `.claude/skills/modugo/SKILL.md`
