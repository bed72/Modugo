# Modugo

**Modugo** é um gerenciador modular de dependências e rotas para Flutter/Dart que organiza o ciclo de vida de módulos, dependências (binds) e rotas, inspirado na arquitetura modular proposta pelo pacote [go_router_modular](https://pub.dev/packages/go_router_modular).

A diferença principal é que o Modugo oferece controle completo de injeção e descarte de dependências por rota ativa, utilizando uma abordagem desacoplada e extensível.

---

## 📦 Recursos

- Registro de **binds** por módulo (singleton, factory, async, lazy, etc.)
- **Ciclo de vida automático** das dependências conforme a rota é acessada ou abandonada
- Suporte a **módulos importados** (aninhamento)
- Injeção **assíncrona** com controle de dependências
- **Descarte automático** das dependências não utilizadas
- Integração com **GoRouter** para gerenciamento das rotas
- Suporte a **ShellRoutes** (estilo Flutter Modular)
- Logs detalhados para debugging

---

## 🚀 Instalação

Adicione via path enquanto o pacote não está publicado:

```yaml
dependencies:
  modugo:
    path: ../modugo
```

---

## 🔹 Exemplo de estrutura do projeto

```txt
/lib
  /modules
    /home
      home_page.dart
      home_module.dart
    /profile
      profile_page.dart
      profile_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

### main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
```

### app_widget.dart

```dart
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: Modugo.routerConfig,
      title: 'Modugo App',
    );
  }
}
```

### app_module.dart

```dart
class AppModule extends Module {
  @override
  List<SyncBind> get syncBinds => [
    SyncBind.singleton<AuthService>((_) => AuthService()),
  ];

  @override
  List<ModuleInterface> get routes => [
    ModuleRoute('/', module: HomeModule()),
    ModuleRoute('/profile', module: ProfileModule()),
  ];
}
```

---

## 💊 Injeção de Dependência

### Tipos suportados:

- `SyncBind.singleton<T>`
- `SyncBind.lazySingleton<T>`
- `SyncBind.factory<T>`
- `AsyncBind<T>` com ou sem `dispose`

### Exemplo:

```dart
class HomeModule extends Module {
  @override
  List<SyncBind> get syncBinds => [
    SyncBind.singleton<HomeController>((i) => HomeController()),
    SyncBind.lazySingleton<Repository>((i) => RepositoryImpl()),
  ];

  @override
  List<AsyncBind> get asyncBinds => [
    AsyncBind<SharedPreferences>((_) async => await SharedPreferences.getInstance()),
  ];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/home', child: (context, state) => const HomePage()),
  ];
}
```

## ⚖️ Ciclo de Vida

- As dependências são registradas **automaticamente** ao navegar para uma rota de módulo.
- Quando todas as rotas do módulo são removidas da árvore, os binds são **descartados automaticamente** (com suporte a dispose).
- O `AppModule` é permanente e seus binds nunca são descartados.

---

## 🛣️ Navegação com rotas

### ChildRoute (equivalente ao GoRoute):

```dart
ChildRoute('/home', child: (context, state) => const HomePage()),
```

### ModuleRoute (rota que instancia um módulo completo):

```dart
ModuleRoute('/profile', module: ProfileModule()),
```

### ShellModuleRoute (similar ao ShellRoute do GoRouter):

```dart
ShellModuleRoute(
  builder: (context, state, child) => MyShell(child: child),
  routes: [
    ChildRoute('/tab1', child: (context, state) => const Tab1Page()),
    ChildRoute('/tab2', child: (context, state) => const Tab2Page()),
  ],
),
```

---

## 🚧 Boas práticas

- Sempre tipar as dependências no bind:

```dart
✅ SyncBind.singleton<MyService>((i) => MyService())
❌ SyncBind.singleton((i) => MyService())
```

- Utilize `AsyncBind` para objetos que dependem de inicialização como `SharedPreferences`, conexões ou caches assíncronos.
- Prefira dividir sua aplicação em pequenos módulos e usar `ModuleRoute` para composição.

---

## 📊 Status

- Em desenvolvimento ativo
- Totalmente testado com exemplos reais
- Planejado para publicação no Pub.dev em breve

---

## 🙌 Agradecimentos

Inspirado diretamente por [go_router_modular](https://pub.dev/packages/go_router_modular) de [Eduardo H. R. Muniz](https://github.com/eduardohr-muniz) e o padrão de módulos de frameworks como Flutter Modular e Angular.

---

## 🙋‍ Contribuições

Pull requests, feedbacks e melhorias são super bem-vindos!

---

## ⚙️ Licença

Este projeto está licenciado sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
