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

### CAP-INJ-07: Desregistro (raro)

O Modugo não auto-remove dependências. Para remover manualmente:

```dart
i.unregister<T>()
i.resetLazySingleton<T>()  // força criação na próxima chamada
```

---

## Restrições

- Todas as dependências são **globais** — não há escopo por módulo ou por rota
- `binds()` NÃO aceita parâmetros — o getter `i` já fornece acesso ao GetIt
- Tentar registrar o mesmo tipo duas vezes lança `AssertionError` (GetIt padrão)
  — a não ser que `allowReassignment` esteja habilitado
- `dispose()` do módulo NÃO remove dependências do GetIt automaticamente
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
