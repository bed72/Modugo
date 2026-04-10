## Why

`IEvent.on<T>(autoDispose: false)` cria uma `StreamSubscription` que nunca é armazenada nem
retornada ao caller — não há API para cancelá-la depois do registro. Uma vez registrada, a
subscription vive indefinidamente, mesmo após `module.dispose()`. Este comportamento está
documentado como `DESIGN-14` no repositório mas nunca foi corrigido. O segundo problema
relacionado — a ordem de cleanup entre `IEvent.dispose()` e `GetIt.reset()` — não está documentada
na API pública, apenas em testes internos, levando a `ServiceNotFoundException` silenciosa em
apps que fazem logout ou reinicialização de módulos.

## What Changes

- Alterar a assinatura de `IEvent.on<T>()` de `void` para `StreamSubscription<T>` — o caller
  recebe o handle e pode cancelar manualmente quando necessário (**BREAKING** apenas para callers
  que atribuíam o retorno void a uma variável, o que não acontece nos call sites atuais)
- Remover a anotação `[DESIGN-14]` dos testes de `event_mixin_auto_dispose_test.dart` e inverter
  as asserções para refletir o comportamento corrigido
- Adicionar documentação de docstring em `IEvent.dispose()` especificando a ordem obrigatória
  de cleanup: IEvent antes de GetIt
- Adicionar aviso via `Logger.warn` dentro de `dispose()` se `GetIt.instance.hasRegistrations`
  já for `false` no momento do dispose (indicativo de ordem incorreta)

## Capabilities

### New Capabilities

- `ievent-subscription-handle`: `IEvent.on<T>()` retorna `StreamSubscription<T>`, permitindo
  cancelamento manual de subscriptions registradas com `autoDispose: false`

### Modified Capabilities

- `events`: comportamento de `IEvent.on<T>()` modificado — retorno passa de `void` para
  `StreamSubscription<T>`; semântica de `autoDispose: true` permanece idêntica

## Impact

- **`lib/src/mixins/event_mixin.dart`** — assinatura de `on<T>()` alterada; docstrings atualizadas
- **`test/mixins/event_mixin_auto_dispose_test.dart`** — testes DESIGN-14 invertidos/removidos;
  novos testes verificando retorno e cancelamento manual
- **Compatibilidade:** call sites existentes que ignoram o retorno de `on<T>()` continuam
  compilando sem mudança — Dart permite ignorar valores de retorno
