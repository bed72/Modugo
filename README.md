# Modugo

**Modugo** é um gerenciador modular de dependências e rotas para Flutter/Dart que organiza o ciclo de vida de módulos, dependências e rotas, inspirado na arquitetura modular proposta pelo pacote [go_router_modular](https://pub.dev/packages/go_router_modular).

A diferença principal é que o Modugo oferece controle completo e desacoplado da **injeção e descarte automático de dependências conforme a navegação**, com logs detalhados e estrutura extensível.

---

## 📦 Recursos

- Registro de **dependências por módulo** com `singleton`, `factory` e `lazySingleton`
- **Ciclo de vida automático** conforme a rota é acessada ou abandonada
- Suporte a **módulos importados** (aninhamento)
- **Descarte automático** de dependências não utilizadas
- Integração com **GoRouter**
- Suporte a `ShellRoute` e `StatefulShellRoute`
- Logs detalhados e configuráveis

---

## 🚀 Instalação

```yaml
dependencies:
  modugo: x.x.x
```

---

## 🔹 Exemplo de estrutura do projeto

```
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

---

### main.dart

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
```

---

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

---

### app_module.dart

```dart
class AppModule extends Module {
  @override
  List<void Function(IInjector)> get binds => [
    (i) => i.addSingleton<AuthService>((_) => AuthService()),
  ];

  @override
  List<IModule> get routes => [
    ModuleRoute('/', module: HomeModule()),
    ModuleRoute('/profile', module: ProfileModule()),
  ];
}
```

---

## 💊 Injeção de Dependência

### Tipos suportados

- `addSingleton<T>((i) => ...)`
- `addLazySingleton<T>((i) => ...)`
- `addFactory<T>((i) => ...)`

### Exemplo

```dart
class HomeModule extends Module {
  @override
  List<void Function(IInjector)> get binds => [
    (i) => i
      ..addSingleton<HomeController>((i) => HomeController(i.get()))
      ..addLazySingleton<Repository>((i) => RepositoryImpl())
      ..addFactory<DateTime>((_) => DateTime.now()),
  ];

  @override
  List<IModule> get routes => [
    ChildRoute('/home', child: (context, state) => const HomePage()),
  ];
}
```

---

## ⚖️ Ciclo de Vida

- Dependências são registradas **automaticamente** ao acessar uma rota de módulo.
- Ao sair de todas as rotas daquele módulo, as dependências são **descartadas automaticamente**.
- O descarte respeita `.dispose`, `.close` ou `StreamController.close()`.
- O `AppModule` nunca é descartado (módulo raiz).
- Dependências em módulos importados são compartilhadas e removidas apenas quando todos os consumidores forem descartados.

---

## 🚣 Navegação

### `ChildRoute`

```dart
ChildRoute('/home', child: (context, state) => const HomePage()),
```

### `ModuleRoute`

```dart
ModuleRoute('/profile', module: ProfileModule()),
```

### `ShellModuleRoute`

```dart
ShellModuleRoute(
  builder: (context, state, child) => MyShell(child: child),
  routes: [
    ChildRoute('/tab1', child: (_, __) => const Tab1Page()),
    ChildRoute('/tab2', child: (_, __) => const Tab2Page()),
  ],
  binds: [
    (i) => i.addLazySingleton(() => TabController()),
  ],
)
```

### `StatefulShellModuleRoute`

```dart
StatefulShellModuleRoute(
  builder: (context, state, shell) => BottomNavBar(shell: shell),
  routes: [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
    ModuleRoute(path: '/favorites', module: FavoritesModule()),
  ],
)
```

---

## 🔍 Acesso às dependências

```dart
final controller = Modugo.get<HomeController>();
```

Ou via contexto com extensão:

```dart
final controller = context.read<HomeController>();
```

---

## 🧰 Logs e Diagnóstico

```dart
Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,
);
```

- Todos os logs passam pela classe `Logger`, que pode ser estendida ou customizada.
- Logs incluem: injeção, descarte, navegação e falhas.

---

## 🧼 Boas práticas

- Sempre tipar o tipo do `addSingleton, addlazySingleton` e `addFactory` explicitamente.
- Dividir a aplicação em **módulos pequenos e coesos**.
- Usar `AppModule` apenas para **dependências globais**.

---

## 🤝 Contribuições

Pull requests, sugestões e melhorias são bem-vindos!

---

## ⚙️ Licença

MIT ©
