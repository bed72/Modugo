# Injeção de Dependências

O Modugo possui um **sistema de DI próprio** com container leve, scoping por módulo e dispose automático. As dependências são registradas dentro de módulos e podem ser acessadas de qualquer widget via `context.read<T>()`.

---

## Registrando Dependências

Dentro de cada módulo, registre **binds** usando o método `binds()`:

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [CoreModule()];

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (context, state) => const HomePage()),
  ];

  @override
  void binds() {
    i.addSingleton<ServiceRepository>(
      () => ServiceRepository.instance,
      onDispose: (repo) => repo.close(),
    );
    i.addLazySingleton<OtherServiceRepository>(
      () => OtherServiceRepositoryImpl(),
    );
  }
}
```

### Tipos de registro

| Método | Comportamento |
|--------|---------------|
| `i.addSingleton<T>(() => T())` | Instância única, criada no primeiro `get<T>()`. Aceita `onDispose` callback. |
| `i.addLazySingleton<T>(() => T())` | Mesmo que singleton — criado no primeiro acesso. Aceita `onDispose` callback. |
| `i.add<T>(() => T())` | Factory — nova instância criada a cada `get<T>()`. Sem dispose (não guarda referência). |

> `i` é o **Container** — o container de DI do Modugo.

### Resolvendo dependências no factory

Use `i` para resolver outras dependências dentro do factory:

```dart
i.addSingleton<HomeController>(
  () => HomeController(i.get<ApiClient>()),
);
```

### Callback `onDispose`

Declare como limpar cada dependência no momento do registro:

```dart
i.addSingleton<Database>(
  () => Database(),
  onDispose: (db) => db.close(),
);
```

O `onDispose` é chamado automaticamente quando o módulo é disposto (via `dispose()` ou `disposeOnExit`).

---

## Acessando Dependências

```dart
// Dentro do módulo
final service = i.get<ServiceRepository>();

// Via Modugo (global)
final service = Modugo.container.get<ServiceRepository>();

// Via BuildContext (recomendado em widgets)
final service = context.read<ServiceRepository>();

// Versão safe (retorna null se não registrado)
final service = context.tryRead<ServiceRepository>();
```

---

## Ciclo de Vida e Dispose

### Dispose manual

```dart
final module = ProfileModule();
module.dispose(); // Dispõe todos os binds do módulo em ordem reversa
```

O `dispose()`:
1. Chama `onDispose` de cada singleton (em ordem reversa de registro)
2. Remove os bindings do container
3. Remove o módulo do registro — permitindo re-registro se o usuário voltar

### Dispose automático com `disposeOnExit`

```dart
ModuleRoute(
  path: '/profile',
  module: ProfileModule(),
  disposeOnExit: true, // dispõe automaticamente ao sair da rota
)
```

Quando `disposeOnExit: true`, o módulo é disposto automaticamente quando o widget sai da árvore (ex: navegação para outra rota).

> **Nota:** Não use `disposeOnExit` em módulos dentro de `StatefulShellModuleRoute`, pois tabs mantêm estado e o widget pode ser desmontado/remontado.

### Re-navegação (goBack)

Após o dispose, se o usuário navegar de volta ao módulo, `binds()` roda novamente e novas instâncias são criadas:

```
1. Usuário entra em /profile → binds() registra ProfileController
2. Usuário sai → dispose() limpa tudo
3. Usuário volta → binds() roda de novo → nova instância de ProfileController
```

---

## Proteções

### Registro duplicado

Registrar o mesmo tipo duas vezes lança `StateError`:

```dart
i.addSingleton<Database>(() => Database());
i.addSingleton<Database>(() => Database()); // StateError!
```

### Dependência circular

O container detecta dependências circulares e lança `StateError` descritivo:

```dart
// A depende de B, B depende de A → StateError com a cadeia completa
```

---

## Exemplo Visual

```
[HomeModule] ---> Singleton(ServiceRepository) + onDispose
              \-> LazySingleton(OtherServiceRepository)

[ProfileModule] ---> importa HomeModule
                     Singleton(ServiceRepository) já compartilhado
                     LazySingleton(ProfileService) + onDispose
```

---

## Acesso via Context Extension

### `context.read<T>()`

Recupera uma dependência registrada. Lança `StateError` se não encontrada:

```dart
final controller = context.read<HomeController>();
```

### `context.tryRead<T>()`

Versão safe — retorna `null` se não encontrada:

```dart
final service = context.tryRead<MyService>() ?? fallbackService;
```
