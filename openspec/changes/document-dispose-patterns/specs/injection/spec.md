## ADDED Requirements

### Requirement: Dispose callback no registro

O Modugo DEVE documentar que o GetIt aceita um parâmetro `dispose:` em
`registerSingleton` e `registerLazySingleton`. Este callback é chamado
quando a instância é removida via `unregister()`, `reset()` ou `popScope()`.

```dart
void binds() {
  i.registerSingleton<DatabaseService>(
    DatabaseService(),
    dispose: (service) => service.close(),
  );

  i.registerLazySingleton<WebSocketClient>(
    () => WebSocketClient(),
    dispose: (client) => client.disconnect(),
  );
}
```

O callback NÃO é chamado automaticamente ao navegar ou ao sair do app.
O desenvolvedor DEVE invocar explicitamente `unregister()` ou `reset()`.

#### Scenario: dispose callback chamado no unregister

- **WHEN** uma dependência é registrada com `dispose:` callback
- **WHEN** `i.unregister<T>()` é chamado
- **THEN** o callback `dispose:` DEVE ser executado antes da remoção

#### Scenario: dispose callback chamado no reset

- **WHEN** dependências são registradas com `dispose:` callbacks
- **WHEN** `i.reset()` é chamado
- **THEN** todos os callbacks `dispose:` DEVEM ser executados na ordem reversa de registro

#### Scenario: dispose callback NÃO chamado automaticamente

- **WHEN** uma dependência é registrada com `dispose:` callback
- **WHEN** nenhum método de remoção é invocado
- **THEN** o callback NÃO DEVE ser executado

### Requirement: Interface Disposable do GetIt

O Modugo DEVE documentar que o GetIt reconhece a interface `Disposable`.
Quando uma instância implementa `Disposable`, o GetIt chama `onDispose()`
automaticamente em `reset()` ou `popScope()`, sem necessidade de passar
`dispose:` callback no registro.

```dart
class CacheService implements Disposable {
  @override
  FutureOr onDispose() {
    // limpar cache
  }
}

void binds() {
  // GetIt detecta Disposable e chama onDispose() no reset/popScope
  i.registerSingleton<CacheService>(CacheService());
}
```

#### Scenario: onDispose chamado automaticamente no reset

- **WHEN** uma instância que implementa `Disposable` é registrada
- **WHEN** `i.reset()` é chamado
- **THEN** `onDispose()` DEVE ser executado automaticamente

#### Scenario: onDispose chamado no popScope

- **WHEN** uma instância que implementa `Disposable` é registrada dentro de um scope
- **WHEN** `i.popScope()` é chamado
- **THEN** `onDispose()` DEVE ser executado para instâncias do scope

### Requirement: Scopes do GetIt para agrupamento de dependências

O Modugo DEVE documentar que o GetIt suporta scopes hierárquicos via
`pushNewScope()` e `popScope()`. Registros em um scope mais alto
sobrescrevem registros de scopes inferiores. `popScope()` remove todos
os registros do scope atual e chama seus dispose callbacks.

```dart
// Criar scope para feature temporária
i.pushNewScope(scopeName: 'checkout');
i.registerSingleton<PaymentService>(PaymentService());

// Quando não precisa mais
await i.popScope(); // remove PaymentService e chama dispose
```

#### Scenario: popScope remove registros do scope e chama dispose

- **WHEN** dependências são registradas dentro de um named scope
- **WHEN** `i.popScope()` é chamado
- **THEN** todas as dependências do scope DEVEM ser removidas
- **THEN** dispose callbacks DEVEM ser chamados

#### Scenario: scope filho sobrescreve registro do pai

- **WHEN** um tipo T é registrado no scope base
- **WHEN** `pushNewScope()` é chamado e T é registrado novamente
- **THEN** `i.get<T>()` DEVE retornar a instância do scope filho
- **THEN** após `popScope()`, `i.get<T>()` DEVE retornar a instância do scope base

### Requirement: Unregister individual com callback

O Modugo DEVE documentar que `i.unregister<T>()` aceita um
`disposingFunction` opcional que sobrescreve qualquer `dispose:` callback
passado no registro.

```dart
i.unregister<MyService>(
  disposingFunction: (service) => service.cleanup(),
);
```

#### Scenario: disposingFunction sobrescreve callback original

- **WHEN** uma dependência é registrada com `dispose:` callback A
- **WHEN** `unregister()` é chamado com `disposingFunction:` callback B
- **THEN** apenas callback B DEVE ser executado (A é ignorado)
