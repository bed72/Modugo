# Spec: Injection (DI)

**ID:** injection
**Status:** stable
**Version:** 4.x

## Overview

O sistema de injeção de dependências do Modugo é uma camada sobre o **GetIt**
(`^9.x`). Módulos registram suas dependências em `binds()` usando o getter `i`
(`GetIt.instance`). As dependências são globais e vivem por toda a vida do app.

---

## Capacidades

### CAP-INJ-01: Registro de dependências

Dentro de `binds()`, use o getter `i` para registrar:

```dart
void binds() {
  i
    // Singleton — instância única já criada
    ..registerSingleton<AuthService>(AuthService())

    // Lazy Singleton — criado na primeira chamada a get<T>()
    ..registerLazySingleton<HomeController>(() => HomeController())

    // Factory — nova instância a cada get<T>()
    ..registerFactory<FormValidator>(() => FormValidator())

    // Singleton assíncrono
    ..registerSingletonAsync<ConfigService>(() async {
      final cfg = ConfigService();
      await cfg.init();
      return cfg;
    })

    // Com dependências declaradas (aguarda outros tipos estarem prontos)
    ..registerSingletonWithDependencies<ApiClient>(
      () => ApiClient(i.get<ConfigService>()),
      dependsOn: [ConfigService],
    )

    // Factory assíncrona
    ..registerFactoryAsync<DbConnection>(() async => await DbConnection.open());
}
```

### CAP-INJ-02: Tipos de registro

| Método | Instâncias | Criação |
|---|---|---|
| `registerSingleton<T>(instance)` | 1 | Imediata (eager) |
| `registerLazySingleton<T>(factory)` | 1 | Na primeira chamada a `get<T>()` |
| `registerFactory<T>(factory)` | N (uma por chamada) | A cada `get<T>()` |
| `registerSingletonAsync<T>(asyncFactory)` | 1 | Imediata assíncrona |
| `registerSingletonWithDependencies<T>(factory, dependsOn:)` | 1 | Após deps prontas |
| `registerFactoryAsync<T>(asyncFactory)` | N | A cada `getAsync<T>()` |

**Parâmetro `instanceName`:** permite múltiplas instâncias do mesmo tipo:

```dart
i.registerSingleton<Database>(PrimaryDb(), instanceName: 'primary');
i.registerSingleton<Database>(ReplicaDb(), instanceName: 'replica');
```

### CAP-INJ-03: Resolução de dependências

```dart
// Dentro de módulo (getter i)
final service = i.get<AuthService>();
final db = i.get<Database>(instanceName: 'primary');

// Global (equivalentes)
Modugo.i.get<T>()
GetIt.instance.get<T>()

// Via BuildContext (extension — preferido em widgets)
context.read<T>()
context.read<T>(instanceName: 'primary')
context.read<T>(param1: value, param2: value)  // factories parametrizadas

// Assíncrono
await context.readAsync<T>()
await Modugo.i.getAsync<T>()
```

### CAP-INJ-04: Parâmetros de factories

GetIt suporta até dois parâmetros em factories parametrizadas:

```dart
// Registro
i.registerFactoryParam<Widget, String, int>(
  (title, count) => MyWidget(title: title, count: count),
);

// Resolução
context.read<Widget>(param1: 'Hello', param2: 42);
i.get<Widget>(param1: 'Hello', param2: 42);
```

### CAP-INJ-05: Dependências entre módulos

Módulos importados têm seus `binds()` executados antes do módulo importador.
Isso garante que as dependências estejam disponíveis quando `binds()` do
importador rodar:

```dart
final class ProfileModule extends Module {
  @override
  List<IBinder> imports() => [CoreModule(), AuthModule()];

  @override
  void binds() {
    // CoreModule e AuthModule já foram registrados
    i.registerLazySingleton<ProfileController>(
      () => ProfileController(
        apiClient: i.get<ApiClient>(),     // de CoreModule
        authService: i.get<AuthService>(), // de AuthModule
      ),
    );
  }
}
```

### CAP-INJ-06: Verificação de registro

```dart
// Verificar se está registrado
i.isRegistered<T>()
i.isRegistered<T>(instanceName: 'primary')

// Verificar se async singleton está pronto
await i.isReady<T>()
await i.allReady()   // aguarda todos os singletons assíncronos
```

### CAP-INJ-07: Desregistro e cleanup

O Modugo não auto-remove dependências. O GetIt oferece mecanismos de cleanup
que o desenvolvedor invoca explicitamente:

```dart
// Remover uma dependência específica
i.unregister<T>()
i.unregister<T>(disposingFunction: (t) => t.close())  // com cleanup

// Recriar lazy singleton na próxima chamada
i.resetLazySingleton<T>()

// Resetar tudo (chama todos os dispose callbacks, ordem reversa)
await i.reset()
```

### CAP-INJ-08: Dispose callback no registro

O parâmetro `dispose:` pode ser passado a `registerSingleton` e
`registerLazySingleton`. O callback é chamado quando a instância é removida
via `unregister()`, `reset()` ou `popScope()` — nunca automaticamente.

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

### CAP-INJ-09: Interface Disposable

Quando uma instância implementa a interface `Disposable` do GetIt, o método
`onDispose()` é chamado automaticamente em `reset()` ou `popScope()`, sem
necessidade de passar `dispose:` no registro:

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

### CAP-INJ-10: Scopes hierárquicos

O GetIt suporta scopes para agrupar registros com ciclo de vida limitado.
Registros em um scope filho sobrescrevem registros do pai. `popScope()`
remove todos os registros do scope e chama seus dispose callbacks:

```dart
// Criar scope para feature temporária
i.pushNewScope(scopeName: 'checkout');
i.registerSingleton<PaymentService>(PaymentService());

// Quando não precisa mais
await i.popScope();  // remove PaymentService e chama dispose

// Scope nomeado — pode ser removido diretamente
await i.dropScope('checkout');
```

---

## Restrições

- Todas as dependências são **globais** — não há escopo por módulo ou por rota
  (a menos que o dev use scopes explicitamente)
- `binds()` NÃO aceita parâmetros — o getter `i` já fornece acesso ao GetIt
- Tentar registrar o mesmo tipo duas vezes lança `AssertionError` (GetIt padrão)
  — a não ser que `allowReassignment` esteja habilitado
- Dispose callbacks NÃO são chamados automaticamente — requerem invocação
  explícita de `unregister()`, `reset()` ou `popScope()`
- `registerSingletonAsync` deve ser aguardado via `i.allReady()` antes de `runApp()`
  se a dep for necessária imediatamente

---

## Casos de teste obrigatórios

- [ ] `registerSingleton` retorna sempre a mesma instância
- [ ] `registerLazySingleton` cria instância apenas na primeira chamada
- [ ] `registerFactory` cria nova instância a cada chamada
- [ ] Módulo importado tem seus binds disponíveis no módulo importador
- [ ] `context.read<T>()` resolve dependência registrada
- [ ] `context.readAsync<T>()` resolve singleton assíncrono
- [ ] `instanceName` diferencia instâncias do mesmo tipo
- [ ] Módulo registrado duas vezes não re-executa `binds()`
- [ ] `dispose:` callback é chamado no `unregister()`
- [ ] `dispose:` callback é chamado no `reset()`
- [ ] `dispose:` callback NÃO é chamado sem invocação explícita
- [ ] `Disposable.onDispose()` é chamado automaticamente no `reset()`
- [ ] `popScope()` remove registros do scope e chama dispose callbacks
- [ ] Scope filho sobrescreve registro do pai
- [ ] `popScope()` restaura registro do scope anterior
