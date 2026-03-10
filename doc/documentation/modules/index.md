# Arquitetura Modular em Flutter

Em uma arquitetura modular, seu app é dividido em **módulos independentes**, cada um responsável por um recurso ou domínio específico. Essa abordagem melhora a **escalabilidade, testabilidade e manutenibilidade**.

---

## Estrutura de Projeto Exemplo

```
/lib
  /modules
    /home
      home_page.dart
      home_module.dart
    /profile
      profile_page.dart
      profile_module.dart
    /chat
      chat_page.dart
      chat_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

- `/modules`: contém todos os módulos de recursos do app.
- Cada pasta de módulo (ex.: `home`, `profile`, `chat`) contém:

  - `*_page.dart`: a interface principal do módulo
  - `*_module.dart`: responsável pelo **roteamento** e **injeção de dependências** do módulo

- `app_module.dart`: módulo raiz que agrega todos os módulos de recursos e dependências globais
- `app_widget.dart`: widget principal que inicializa o app com rotas e configuração de módulos
- `main.dart`: ponto de entrada do app

---

## Como os Módulos Funcionam

1. **Encapsulamento**: Cada módulo gerencia suas próprias rotas, dependências e interface.
2. **Roteamento**: Os módulos definem suas próprias rotas, que são posteriormente compostas pelo módulo raiz.
3. **Injeção de Dependência**: Cada módulo registra suas dependências no `Container` com suporte a dispose.
4. **Escalabilidade**: Novos recursos podem ser adicionados como novos módulos sem afetar os existentes.

---

## Anatomia de um Module

A classe `Module` é a base de tudo no Modugo. Ela combina três responsabilidades:

| Método | Responsabilidade |
|--------|------------------|
| `binds()` | Registra dependências no `Container` |
| `routes()` | Declara as rotas expostas pelo módulo |
| `imports()` | Declara dependências de outros módulos |
| `initState()` | Executado quando o módulo é inicializado |
| `dispose()` | Dispõe bindings do módulo e permite re-registro |

---

## Exemplo: Módulo App

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.addSingleton<AuthService>(
      () => AuthService(),
      onDispose: (auth) => auth.close(),
    );
  }

  @override
  List<IRoute> routes() => [
    module('/home', HomeModule()),
    module('/chat', ChatModule()),
    module('/profile', ProfileModule()),
  ];
}
```

- `binds()`: registra dependências com `onDispose` para limpeza automática.
- `routes()`: declara as rotas do módulo.

---

## Importando Módulos com `imports()`

O método `imports()` permite que um módulo declare dependências de outros módulos. Os `binds()` dos módulos importados são executados **antes** dos `binds()` do módulo atual.

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [SharedModule()];

  @override
  void binds() {
    // SharedModule já foi registrado, podemos usar suas dependências
    i.addLazySingleton<HomeController>(
      () => HomeController(i.get<ApiClient>()),
    );
  }

  @override
  List<IRoute> routes() => [
    child(path: '/', child: (_, _) => const HomePage()),
  ];
}
```

### Comportamento do registro

- Cada módulo é registrado **apenas uma vez** (idempotente).
- Se o mesmo módulo for importado por múltiplos módulos, seus `binds()` **não serão executados novamente**.
- Imports são processados **recursivamente** — se `A` importa `B` que importa `C`, a ordem de registro é: `C -> B -> A`.

---

## Ciclo de Vida

### `initState()`

Executado quando o módulo é inicializado. Ideal para configurar listeners, preparar recursos ou executar lógica de setup.

```dart
final class AnalyticsModule extends Module {
  @override
  void initState() {
    super.initState();
    debugPrint('AnalyticsModule inicializado');
  }
}
```

### `dispose()`

Dispõe todos os bindings do módulo (chamando `onDispose` em ordem reversa) e remove o módulo do registro, permitindo re-registro se o usuário navegar de volta.

```dart
final class ChatModule extends Module {
  @override
  void dispose() {
    // Lógica de limpeza customizada ANTES do super
    myCustomCleanup();
    super.dispose(); // Limpa bindings + permite re-registro
  }
}
```

> **Importante:** Sempre chame `super.dispose()` para garantir que os bindings sejam limpos corretamente.

### Dispose automático com `disposeOnExit`

```dart
ModuleRoute(
  path: '/profile',
  module: ProfileModule(),
  disposeOnExit: true, // dispõe automaticamente ao sair da rota
)
```

---

## Benefícios

- **Separação de Responsabilidades**: UI, rotas e dependências são modularizadas.
- **Facilidade de Testes**: Cada módulo pode ser testado de forma independente.
- **Reutilização**: Módulos podem ser reutilizados em diferentes apps.
- **Colaboração em Equipe**: Times podem trabalhar em módulos diferentes simultaneamente sem conflitos.
- **Dispose com Lifecycle**: Bindings são limpos automaticamente com `onDispose` callbacks.

---

## Diagrama de Composição

```
AppModule
├── imports: [CoreModule]
├── binds: AuthService (+ onDispose)
└── routes:
    ├── HomeModule
    │   ├── imports: [SharedModule]
    │   ├── binds: HomeController (+ onDispose)
    │   └── routes: ['/']
    ├── ChatModule
    │   ├── binds: ChatService (+ onDispose)
    │   └── routes: ['/']
    └── ProfileModule (disposeOnExit: true)
        ├── imports: [SharedModule]  <- já registrado, skip
        ├── binds: ProfileController (+ onDispose)
        └── routes: ['/']
```
