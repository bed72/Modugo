## ADDED Requirements

### Requirement: on<T>() retorna StreamSubscription cancelável
`IEvent.on<T>()` SHALL retornar a `StreamSubscription<T>` criada internamente, permitindo que
o caller cancele manualmente subscriptions registradas com `autoDispose: false`.

#### Scenario: Subscription retornada com autoDispose false pode ser cancelada manualmente
- **WHEN** `on<T>(callback, autoDispose: false)` é chamado
- **THEN** o método retorna uma `StreamSubscription<T>` válida
- **WHEN** o caller chama `cancel()` na subscription retornada
- **THEN** o callback não é mais invocado para eventos subsequentes

#### Scenario: Subscription com autoDispose false não é cancelada pelo dispose do módulo
- **WHEN** `on<T>(callback, autoDispose: false)` é chamado
- **WHEN** `module.dispose()` é chamado
- **THEN** a subscription retornada ainda está ativa
- **THEN** o callback ainda recebe eventos emitidos após o dispose

#### Scenario: Call sites que ignoram o retorno de on<T>() continuam funcionando
- **WHEN** `on<T>(callback)` ou `on<T>(callback, autoDispose: true)` é chamado sem capturar retorno
- **THEN** o comportamento é idêntico ao anterior — subscription gerenciada automaticamente

### Requirement: Documentação de ordem de cleanup IEvent → GetIt
O docstring de `IEvent.dispose()` SHALL especificar que `dispose()` deve ser chamado
**antes** de qualquer operação `GetIt.reset()`, `GetIt.unregister()` ou `GetIt.popScope()`
que remova serviços acessados por listeners ativos.

#### Scenario: Aviso emitido quando dispose é chamado após GetIt reset em modo debug
- **WHEN** `Modugo.configure(debugLogDiagnostics: true)` está ativo
- **WHEN** `GetIt.instance` não possui registros ativos no momento em que `dispose()` é chamado
- **THEN** `Logger.warn` emite mensagem indicando possível ordem incorreta de cleanup
