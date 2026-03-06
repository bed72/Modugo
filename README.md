<p align="center">
  <img src="https://raw.githubusercontent.com/bed72/Modugo/master/images/banner.png" alt="Modugo Logo" />
</p>

# Modugo

**Modugo** é um sistema modular para Flutter inspirado em [Flutter Modular](https://pub.dev/packages/flutter_modular) e [Go Router Modular](https://pub.dev/packages/go_router_modular). Ele organiza sua aplicação em **módulos, rotas e injeção de dependências** de forma clara e escalável. Diferente de outros frameworks, o Modugo **não gerencia descarte automático de módulos**.

📚 **Documentação completa:** [bed72.github.io/Modugo](https://bed72.github.io/Modugo/)

---

## 📖 Sumário

- [Visão Geral](#-visão-geral)
- [Instalação](#-instalação)
- [Primeiros Passos](#️-primeiros-passos)
- [Módulos](#-módulos)
- [Rotas](#-rotas)
- [API Declarativa (DSL)](#-api-declarativa-dsl)
- [Guards](#-guards)
- [Injeção de Dependência](#️-injeção-de-dependência)
- [Sistema de Eventos](#-sistema-de-eventos)
- [Utilitários](#-utilitários)
- [Documentação](#-documentação)
- [Contribuições](#-contribuições)
- [Licença](#-licença)

---

## 🚀 Visão Geral

- Usa **GoRouter** para navegação.
- Usa **GetIt** para injeção de dependências.
- Dependências são registradas **uma única vez** ao iniciar.
- Não há descarte automático — as dependências vivem até o app encerrar.
- **5 tipos de rotas**: `ChildRoute`, `ModuleRoute`, `ShellModuleRoute`, `StatefulShellModuleRoute`, `AliasRoute`.
- **Guards** com propagação automática para submódulos.
- **Sistema de eventos** nativo para comunicação desacoplada.
- **7 transições** de página prontas para uso.
- **Extensions** de contexto para navegação, matching e injeção.

---

## 📦 Instalação

```yaml
dependencies:
  modugo: ^4.2.6
```

---

## ▶️ Primeiros Passos

### 1. Crie o módulo raiz

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>(AuthService());
  }

  @override
  List<IRoute> routes() => [
    route('/', child: (_, _) => const HomePage()),
    module('/profile', ProfileModule()),
  ];
}
```

### 2. Configure no `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
```

### 3. Use o router

```dart
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: modugoRouter);
  }
}
```

> 📚 Guia completo: [Primeiros Passos](https://bed72.github.io/Modugo/documentation/getting-started/)

---

## 🏗 Módulos

Cada módulo encapsula suas rotas, dependências e imports:

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [SharedModule()];

  @override
  void binds() {
    i.registerLazySingleton<HomeController>(
      () => HomeController(i.get<ApiClient>()),
    );
  }

  @override
  List<IRoute> routes() => [
    route('/', child: (_, _) => const HomePage()),
  ];
}
```

- `imports()` — módulos dos quais este depende (registrados antes).
- `binds()` — registra dependências no GetIt.
- `routes()` — declara as rotas do módulo.
- Registro **idempotente**: cada módulo é registrado apenas uma vez.

> 📚 Detalhes: [Módulos](https://bed72.github.io/Modugo/documentation/modules/)

---

## 🧭 Rotas

### Tipos disponíveis

| Tipo | Uso |
|------|-----|
| `ChildRoute` | Telas simples |
| `ModuleRoute` | Submódulos |
| `AliasRoute` | Caminhos alternativos para a mesma tela |
| `ShellModuleRoute` | Layout compartilhado (menus, abas) |
| `StatefulShellModuleRoute` | Navegação com múltiplas pilhas (bottom nav) |

### ShellModuleRoute

```dart
ShellModuleRoute(
  builder: (context, state, child) => Scaffold(body: child),
  routes: [
    ChildRoute(path: '/user', child: (_, _) => const UserPage()),
    ChildRoute(path: '/config', child: (_, _) => const ConfigPage()),
  ],
)
```

### StatefulShellModuleRoute

```dart
StatefulShellModuleRoute(
  builder: (context, state, shell) => BottomBarWidget(shell: shell),
  routes: [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
  ],
)
```

### AliasRoute

```dart
alias(from: '/cart/:id', to: '/order/:id');
```

Tanto `/cart/123` quanto `/order/123` renderizam a mesma tela.

> 📚 Detalhes: [Rotas](https://bed72.github.io/Modugo/documentation/routes/)

---

## 🧩 API Declarativa (DSL)

Sintaxe fluente para definir rotas sem boilerplate:

```dart
final class AppModule extends Module {
  @override
  List<IRoute> routes() => [
    child(child: (_, _) => const HomePage()),
    module(module: AuthModule()),
    alias(from: '/cart/:id', to: '/order/:id'),
    shell(
      builder: (_, _, child) => MainShell(child: child),
      routes: [
        child(path: '/dashboard', child: (_, _) => const DashboardPage()),
      ],
    ),
    statefulShell(
      builder: (_, _, shell) => BottomBarWidget(shell: shell),
      routes: [
        module(module: FeedModule()),
        module(module: ProfileModule()),
      ],
    ),
  ];
}
```

| Helper | Retorna | Uso |
|--------|---------|-----|
| `child()` | `ChildRoute` | Telas simples |
| `module()` | `ModuleRoute` | Submódulos |
| `alias()` | `AliasRoute` | Caminhos alternativos |
| `shell()` | `ShellModuleRoute` | Layouts compartilhados |
| `statefulShell()` | `StatefulShellModuleRoute` | Múltiplas pilhas |

> 📚 Detalhes: [API Declarativa](https://bed72.github.io/Modugo/documentation/routes/dsl/)

---

## 🔒 Guards

Controle de acesso a rotas com lógica condicional:

```dart
final class AuthGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await checkAuth();
    return isLoggedIn ? null : '/login';
  }
}
```

Aplique em rotas individuais ou propague para submódulos:

```dart
// Por rota
route('/', child: (_, _) => const HomePage(), guards: [AuthGuard()]);

// Propagação para todos os filhos
List<IRoute> routes() => propagateGuards(
  guards: [AuthGuard()],
  routes: [
    module('/home', HomeModule()),
    module('/profile', ProfileModule()),
  ],
);
```

> 📚 Detalhes: [Guards](https://bed72.github.io/Modugo/documentation/guards/)

---

## 🛠️ Injeção de Dependência

```dart
final class HomeModule extends Module {
  @override
  void binds() {
    i
      ..registerSingleton<ServiceRepository>(ServiceRepository())
      ..registerLazySingleton<ApiClient>(ApiClient.new);
  }
}
```

Três formas de acessar:

```dart
final service = i.get<ServiceRepository>();
final service = Modugo.i.get<ServiceRepository>();
final service = context.read<ServiceRepository>();
```

> 📚 Detalhes: [Injeção de Dependência](https://bed72.github.io/Modugo/documentation/injection/)

---

## 📡 Sistema de Eventos

Comunicação desacoplada entre módulos:

```dart
// Definir evento
final class UserLoggedInEvent {
  final String userId;
  UserLoggedInEvent(this.userId);
}

// Emitir
Event.emit(UserLoggedInEvent('user-123'));

// Ouvir
Event.i.on<UserLoggedInEvent>((event) {
  print('Logou: ${event.userId}');
});
```

O Modugo emite `RouteChangedEventModel` automaticamente a cada navegação:

```dart
Event.i.on<RouteChangedEventModel>((event) {
  print('Navegou para: ${event.location}');
});
```

> 📚 Detalhes: [Eventos](https://bed72.github.io/Modugo/documentation/events/)

---

## 🧰 Utilitários

### AfterLayoutMixin

Executa código após o primeiro frame do widget:

```dart
class _MyScreenState extends State<MyScreen> with AfterLayoutMixin {
  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    context.read<HomeController>().loadData();
  }
}
```

### CompilerRoute

Validação e extração de parâmetros de rotas:

```dart
final route = CompilerRoute('/user/:id');

route.match('/user/42');     // true
route.extract('/user/42');   // {'id': '42'}
route.build({'id': '42'});   // '/user/42'
```

### Logging

```dart
await Modugo.configure(module: AppModule(), debugLogDiagnostics: true);
```

> 📚 Detalhes: [Utilitários](https://bed72.github.io/Modugo/documentation/utilities/) | [Extensions](https://bed72.github.io/Modugo/documentation/extensions/)

---

## 📚 Documentação

Documentação completa disponível em MkDocs:

👉 **[bed72.github.io/Modugo](https://bed72.github.io/Modugo/)**

| Seção | Descrição |
|-------|-----------|
| [Primeiros Passos](https://bed72.github.io/Modugo/documentation/getting-started/) | Instalação e configuração |
| [Módulos](https://bed72.github.io/Modugo/documentation/modules/) | Arquitetura modular |
| [Rotas](https://bed72.github.io/Modugo/documentation/routes/) | Tipos de rotas e navegação |
| [API Declarativa](https://bed72.github.io/Modugo/documentation/routes/dsl/) | DSL fluente para rotas |
| [Transições](https://bed72.github.io/Modugo/documentation/routes/transitions/) | Animações de página |
| [Injeção](https://bed72.github.io/Modugo/documentation/injection/) | GetIt e context extensions |
| [Guards](https://bed72.github.io/Modugo/documentation/guards/) | Proteção de rotas |
| [Eventos](https://bed72.github.io/Modugo/documentation/events/) | Comunicação entre módulos |
| [Extensions](https://bed72.github.io/Modugo/documentation/extensions/) | Extensions de BuildContext, GoRouterState e Uri |
| [Utilitários](https://bed72.github.io/Modugo/documentation/utilities/) | AfterLayoutMixin, CompilerRoute, Logger |
| [Migração](https://bed72.github.io/Modugo/documentation/migration/) | Guia v2 → v3 → v4 |

---

## 🤝 Contribuições

Pull requests e sugestões são bem-vindos! 💜

---

## 📜 Licença

MIT ©
