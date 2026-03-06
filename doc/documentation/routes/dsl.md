# 🧩 API Declarativa (DSL)

O Modugo oferece uma API declarativa e fluente para definir rotas dentro dos seus módulos. Ela elimina a repetição de código, tornando a configuração mais expressiva e legível.

---

## 🔹 Visão Geral

Tradicionalmente, você define rotas assim:

```dart
List<IRoute> routes() => [
  ChildRoute(path: '/', child: (_, _) => const HomePage()),
  ModuleRoute(path: '/auth', module: AuthModule()),
  AliasRoute(from: '/cart/:id', to: '/order/:id'),
];
```

Com a DSL, o mesmo código fica:

```dart
List<IRoute> routes() => [
  route('/', child: (_, _) => const HomePage()),
  module('/auth', AuthModule()),
  alias(from: '/cart/:id', to: '/order/:id'),
];
```

A lógica interna é **exatamente a mesma** — a DSL é apenas açúcar sintático.

---

## 🔹 Métodos Disponíveis

### `child()` — Cria uma ChildRoute

Para rotas simples que apontam diretamente para um widget.

```dart
child(
  path: '/home',
  name: 'home',
  child: (_, _) => const HomePage(),
  guards: [AuthGuard()],
  transition: TypeTransition.fade,
  onExit: (context, state) async => true,
  pageBuilder: (_, _) => const MaterialPage(child: HomePage()),
  parentNavigatorKey: myKey,
);
```

> Se `path` não for informado, o valor padrão é `'/'`.

---

### `module()` — Cria uma ModuleRoute

Conecta submódulos para uma arquitetura hierárquica.

```dart
module(
  module: AuthModule(),
  name: 'auth',
  parentNavigatorKey: myKey,
);
```

> O `path` padrão é `'/'`.

---

### `alias()` — Cria uma AliasRoute

Apelidos para rotas existentes sem duplicar lógica.

```dart
alias(from: '/cart/:id', to: '/order/:id');
```

---

### `shell()` — Cria uma ShellModuleRoute

Agrupa rotas sob um layout compartilhado.

```dart
shell(
  builder: (_, _, child) => AppScaffold(child: child),
  routes: [
    route('/feed', child: (_, _) => const FeedPage()),
    route('/settings', child: (_, _) => const SettingsPage()),
  ],
  observers: [MyObserver()],
  navigatorKey: shellKey,
  parentNavigatorKey: parentKey,
  pageBuilder: (_, _, child) => MaterialPage(child: child),
);
```

---

### `statefulShell()` — Cria uma StatefulShellModuleRoute

Navegação com múltiplas pilhas independentes (abas, bottom navigation).

```dart
statefulShell(
  builder: (_, _, shell) => BottomBarWidget(shell: shell),
  routes: [
    module('/home', HomeModule()),
    module('/profile', ProfileModule()),
  ],
  key: shellKey,
  parentNavigatorKey: parentKey,
);
```

---

## 🔹 Tabela de Resumo

| Helper | Retorna | Uso Principal |
|--------|---------|---------------|
| `child()` | `ChildRoute` | Telas simples |
| `module()` | `ModuleRoute` | Submódulos |
| `alias()` | `AliasRoute` | Caminhos alternativos |
| `shell()` | `ShellModuleRoute` | Containers e layouts compartilhados |
| `statefulShell()` | `StatefulShellModuleRoute` | Navegação com múltiplas pilhas |

---

## 🔹 Exemplo Completo

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
        child(path: '/settings', child: (_, _) => const SettingsPage()),
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

> A DSL transforma suas definições de rota em uma linguagem fluente e legível, mantendo os módulos elegantes e escaláveis.
