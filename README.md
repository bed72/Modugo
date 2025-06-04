# Modugo

**Modugo** é um gerenciador modular de dependências e rotas para Flutter/Dart que organiza o ciclo de vida de módulos, binds e rotas, inspirado na arquitetura modular proposta pelo pacote [go_router_modular](https://pub.dev/packages/go_router_modular).

A diferença principal é que o Modugo oferece controle completo e desacoplado da **injeção e descarte automático de dependências conforme a navegação**, com logs detalhados e estrutura extensível.

---

## 📦 Recursos

- Registro de **binds** por módulo (singleton, factory, lazy)
- **Ciclo de vida automático** das dependências conforme a rota é acessada ou abandonada
- Suporte a **módulos importados** (aninhamento)
- **Descarte automático** das dependências não utilizadas
- Integração com **GoRouter** para gerenciamento das rotas
- Suporte a **ShellRoutes** (estilo Flutter Modular)
- Logs detalhados e personalizáveis com suporte à lib `logger`

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
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Modugo.configure(module: AppModule(), initialRoute: '/');

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
  List<Bind> get binds => [
    Bind.singleton<AuthService>((_) => AuthService()),
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

- `Bind.singleton<T>`
- `Bind.lazySingleton<T>`
- `Bind.factory<T>`

### Exemplo:

```dart
class HomeModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.singleton<HomeController>((i) => HomeController()),
    Bind.lazySingleton<Repository>((i) => RepositoryImpl()),
    Bind.factory<DateTime>((_) => DateTime.now()),
  ];

  @override
  List<ModuleInterface> get routes => [
    ChildRoute('/home', child: (context, state) => const HomePage()),
  ];
}
```

---

## ⚖️ Ciclo de Vida

- As dependências são registradas **automaticamente** ao navegar para uma rota de módulo.
- Quando todas as rotas do módulo são removidas da árvore, os binds são **descartados automaticamente**, com suporte a `.dispose`, `.close`, `StreamController` etc.
- O `AppModule` é permanente e seus binds nunca são descartados.
- Módulos importados compartilham dependências entre si e respeitam o tempo de vida dos módulos ativos.

---

## 🚣️ Navegação com rotas

### `ChildRoute` (equivalente ao `GoRoute`):

```dart
ChildRoute('/home', child: (context, state) => const HomePage()),
```

### `ModuleRoute` (rota que instancia um módulo completo):

```dart
ModuleRoute('/profile', module: ProfileModule()),
```

### `ShellModuleRoute` (similar ao `ShellRoute` do `GoRouter`):

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

## 🔍 Acesso às dependências

```dart
final controller = Modugo.get<HomeController>();
```

Também é possível usar o `Injector`:

```dart
final injector = Injector();
final repository = injector.get<Repository>();
```

---

## 🧰 Logs e Diagnóstico

- Os logs de injeção, descarte e navegação são controlados por:

```dart
Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,
);
```

- Os logs usam a classe `ModugoLogger`, que pode ser estendida ou substituída.

---

## 🚧 Boas práticas

- Sempre tipar as dependências no bind:

```dart
📈 Bind.singleton<MyService>((i) => MyService())
🔴 Bind.singleton((i) => MyService())
```

- Prefira dividir sua aplicação em **módulos coesos** e usar `ModuleRoute` para composição e isolamento.
- Evite estados compartilhados globalmente — use `AppModule` para estados globais e outros módulos para recursos locais.

---

## 📊 Status

- Em desenvolvimento ativo
- Testado com exemplos reais
- Planejado para publicação no Pub.dev em breve

---

## 🙌 Agradecimentos

Inspirado diretamente por [go_router_modular](https://pub.dev/packages/go_router_modular) de [Eduardo H. R. Muniz](https://github.com/eduardohr-muniz) e o padrão de módulos de frameworks como Flutter Modular e Angular.

---

## 🤛 Contribuições

Pull requests, feedbacks e melhorias são super bem-vindos!

---

## ⚙️ Licença

Este projeto está licenciado sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
