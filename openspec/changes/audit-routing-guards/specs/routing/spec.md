## MODIFIED Requirements

### Requirement: resetForTesting() limpa estado de guards concorrentes
`Modugo.resetForTesting()` SHALL limpar `FactoryRoute._pendingGuards`, cancelando qualquer
operação pendente e definindo o campo como `null`, garantindo isolamento entre testes.

#### Scenario: _pendingGuards é null após resetForTesting
- **WHEN** uma operação de guards está em andamento
- **WHEN** `Modugo.resetForTesting()` é chamado
- **THEN** `FactoryRoute._pendingGuards` é `null`

### Requirement: AliasRoute com destino inexistente lança erro com mensagem clara
Quando `AliasRoute.to` aponta para um path que não existe como `ChildRoute` direto na lista
de rotas do mesmo módulo, o sistema SHALL lançar `ArgumentError` com mensagem que explica
**a limitação** (AliasRoute só funciona com ChildRoute do mesmo módulo) e o path que foi
buscado e não encontrado.

#### Scenario: ArgumentError menciona limitação de escopo ao não encontrar rota alvo
- **WHEN** `AliasRoute(from: '/x', to: '/not-exist')` é compilado
- **THEN** `ArgumentError` é lançado
- **THEN** a mensagem contém o path `/not-exist` e menciona que AliasRoute só funciona com ChildRoute do mesmo módulo

### Requirement: configureRoutes() é idempotente por instância de módulo
Chamar `configureRoutes()` múltiplas vezes na mesma instância de `Module` SHALL executar
`_configureBinders()` apenas uma vez — não importa quantas vezes seja chamado.

#### Scenario: Segunda chamada a configureRoutes() não duplica event subscriptions
- **WHEN** `module.configureRoutes()` é chamado duas vezes na mesma instância
- **THEN** `listen()` do `IEvent` é invocado apenas uma vez
- **THEN** event listeners não são duplicados

### Requirement: Módulo skipped por Type duplicado emite Logger.warn
Quando `_configureBinders()` skipa um módulo por `runtimeType` já estar em `_modulesRegistered`,
o sistema SHALL emitir `Logger.warn` identificando o Type ignorado.

#### Scenario: Logger.warn emitido ao registrar módulo com Type já registrado
- **WHEN** dois módulos do mesmo `runtimeType` são configurados em sequência
- **WHEN** `debugLogDiagnostics` está ativo
- **THEN** o segundo módulo é ignorado
- **THEN** uma mensagem de warn é emitida identificando o Type skipped
