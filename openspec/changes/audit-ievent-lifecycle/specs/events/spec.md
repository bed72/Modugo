## MODIFIED Requirements

### Requirement: Registro de listener com IEvent.on<T>()
`IEvent.on<T>()` registra um listener para eventos do tipo `T` e retorna a `StreamSubscription<T>`
criada. Se `autoDispose: true` (padrão), a subscription é gerenciada automaticamente pelo
módulo e cancelada no `dispose()`. Se `autoDispose: false`, a subscription é retornada ao caller
para gerenciamento manual; `dispose()` do módulo não a cancela.

#### Scenario: autoDispose true — subscription cancelada no dispose
- **WHEN** `on<T>(callback, autoDispose: true)` é chamado
- **WHEN** `module.dispose()` é chamado
- **THEN** o callback não recebe eventos emitidos após o dispose

#### Scenario: autoDispose false — subscription ativa após dispose do módulo
- **WHEN** `on<T>(callback, autoDispose: false)` é chamado
- **WHEN** `module.dispose()` é chamado
- **THEN** o callback ainda recebe eventos — cancelamento é responsabilidade do caller

#### Scenario: Retorno de on<T>() é StreamSubscription em ambos os casos
- **WHEN** `on<T>(callback)` é chamado com qualquer valor de `autoDispose`
- **THEN** o método retorna uma instância válida de `StreamSubscription<T>`
