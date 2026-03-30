## 1. Implementação

- [x] 1.1 Em `lib/src/mixins/event_mixin.dart`, alterar o tipo de retorno de `on<T>()` de `void` para `StreamSubscription<T>` e adicionar `return sub;` ao final do método
- [x] 1.2 Atualizar o docstring de `on<T>()` para documentar que a subscription retornada pode ser cancelada manualmente quando `autoDispose: false`
- [x] 1.3 Atualizar o docstring de `dispose()` para especificar a ordem obrigatória: chamar `dispose()` **antes** de `GetIt.reset()` / `unregister()` / `popScope()`
- [x] 1.4 `GetIt.instance.hasRegistrations` não existe no GetIt 9.x — warning removido; limpeza de subscriptions preservada

## 2. Atualização dos testes existentes

- [x] 2.1 Em `test/mixins/event_mixin_auto_dispose_test.dart`, remover a marcação `[DESIGN-14]` dos títulos dos testes
- [x] 2.2 Inverter a asserção do teste `autoDispose: false — subscription still fires after module dispose`: após o fix, a subscription **pode** ser cancelada — mas o teste deve verificar que ainda está ativa se o retorno não for usado para cancelar (comportamento esperado permanece o mesmo sem cancelamento manual)
- [x] 2.3 Atualizar o teste `autoDispose: false — on() returns void, caller cannot cancel`: agora `on()` retorna `StreamSubscription`, o teste deve verificar que o retorno é uma `StreamSubscription` válida

## 3. Novos testes de cobertura

- [x] 3.1 Teste: `autoDispose: true` (padrão) — subscription cancelada automaticamente no `dispose()`; callback não é chamado após dispose
- [x] 3.2 Teste: `autoDispose: false` — `on<T>()` retorna `StreamSubscription<T>` não-nula
- [x] 3.3 Teste: `autoDispose: false` — subscription retornada pode ser cancelada manualmente com `.cancel()`; callback não é chamado após cancel manual
- [x] 3.4 Teste: `autoDispose: false` — `module.dispose()` NÃO cancela a subscription; callback ainda ativo após dispose do módulo
- [x] 3.5 Teste: múltiplas chamadas a `on<T>(autoDispose: true)` — todas canceladas no `dispose()`
- [x] 3.6 Teste: múltiplas chamadas a `on<T>(autoDispose: false)` — cada retorno é uma subscription independente e cancelável
- [x] 3.7 Teste: call site que ignora retorno de `on<T>(autoDispose: true)` — sem warning de compilação, comportamento idêntico ao anterior
- [x] 3.8 Teste: after `module.dispose()`, novas chamadas a `Event.emit<T>` não chegam aos listeners cancelados (autoDispose: true)
- [x] 3.9 Teste: after `module.dispose()`, novas chamadas a `Event.emit<T>` ainda chegam a listeners com `autoDispose: false` que não foram cancelados manualmente

## 4. Verificação

- [x] 4.1 Rodar `flutter test test/mixins/` e confirmar que todos os testes passam
- [x] 4.2 Rodar `flutter test` completo — zero regressões
- [x] 4.3 Rodar `flutter analyze` — zero warnings
- [x] 4.4 Rodar `dart format --set-exit-if-changed lib test`
