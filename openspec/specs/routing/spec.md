# Spec: Routing

**ID:** routing
**Status:** stable
**Version:** 4.x

## Overview

O sistema de roteamento do Modugo é baseado no GoRouter. Ele expõe cinco tipos de
rota (`ChildRoute`, `ModuleRoute`, `AliasRoute`, `ShellModuleRoute`,
`StatefulShellModuleRoute`) e uma DSL declarativa via mixin `IDsl`. A conversão
para o GoRouter é feita internamente por `FactoryRoute.from()`.

---

## Capacidades

### CAP-RTE-01: Bootstrap

A configuração do router DEVE ser feita via `Modugo.configure()` antes de
`runApp()`:

```dart
await Modugo.configure(
  module: AppModule(),
  initialRoute: '/',
  pageTransition: TypeTransition.fade,  // padrão global
);
runApp(const AppWidget());

// AppWidget usa o global 'modugoRouter'
MaterialApp.router(routerConfig: modugoRouter);
```

**Parâmetros obrigatórios:** `module`
**Parâmetros relevantes:**

| Parâmetro | Default | Notas |
|---|---|---|
| `initialRoute` | `'/'` | |
| `pageTransition` | `fade` | Override por rota via `transition:` |
| `debugLogDiagnostics` | `false` | Logs internos Modugo |
| `debugLogDiagnosticsGoRouter` | `false` | Logs GoRouter |
| `redirect` | `null` | Redirect global — executado antes de guards |
| `redirectLimit` | `2` | Max redirects antes de erro |
| `navigatorKey` | `null` | Usa `modugoNavigatorKey` se null |
| `errorBuilder` | `null` | Página de erro customizada |
| `refreshListenable` | `null` | Listenable para re-avaliar redirect/guards |
| `extraCodec` | `null` | Para serializar extras em deep links |
| `observers` | `null` | NavigatorObservers |
| `onException` | `null` | Callback de exceção |

`Modugo.configure()` é **idempotente** — retorna router cacheado se já configurado.

### CAP-RTE-02: ChildRoute

Representa uma página folha mapeada a um path e um widget builder.

```dart
ChildRoute(
  path: '/home',
  name: 'home',                         // opcional — para navegação por nome
  child: (context, state) => const HomePage(),
  guards: [AuthGuard()],                // opcional
  transition: TypeTransition.slideLeft, // opcional — override do global
  onExit: (ctx, state) async => true,  // opcional — confirmação ao sair
  pageBuilder: (ctx, state) => ...,     // opcional — page builder customizado
  parentNavigatorKey: rootKey,          // opcional — eleva ao navigator pai
)
```

**DSL equivalente (método `child()`):**

```dart
child(
  path: '/home',
  child: (_, _) => const HomePage(),
  // ...mesmos parâmetros opcionais
)
```

> **IMPORTANTE:** O método DSL é `child()`, **não** `route()`. Algumas docstrings
> internas usam `route()` por inconsistência histórica, mas o método real é `child()`.

### CAP-RTE-03: ModuleRoute

Delega uma subrota a um módulo inteiro. O path da rota filha é definido no próprio
módulo filho via `routes()`.

```dart
ModuleRoute(path: '/profile', module: ProfileModule())

// DSL — path sempre '/', definido pelo módulo filho
module(module: ProfileModule())
```

**Comportamento:** Os `binds()` do módulo filho são registrados automaticamente
quando a rota é configurada via `configureRoutes()`.

### CAP-RTE-04: AliasRoute

Cria um caminho alternativo para um `ChildRoute` existente no mesmo módulo.
Não duplica a lógica nem causa loops de redirect.

```dart
// 'from' e 'to' são paths relativos ao módulo
alias(from: '/cart/:id', to: '/order/:id')
```

**Limitações:**
- Funciona apenas para `ChildRoute` (não `ModuleRoute`, não `ShellModuleRoute`)
- O destino (`to`) deve existir como `ChildRoute` no mesmo módulo
- Não suporta alias encadeados

### CAP-RTE-05: ShellModuleRoute

Agrupa rotas sob um layout persistente (wrapper). Internamente usa `ShellRoute`
do GoRouter. Ideal para AppBar/Drawer persistentes ou sub-navegação.

```dart
shell(
  builder: (context, state, child) => AppScaffold(child: child),
  routes: [
    child(path: '/feed',     child: (_, _) => const FeedPage()),
    child(path: '/settings', child: (_, _) => const SettingsPage()),
  ],
  navigatorKey: shellKey,          // opcional
  parentNavigatorKey: rootKey,     // opcional — eleva ao navigator pai
  observers: [MyObserver()],       // opcional
)
```

### CAP-RTE-06: StatefulShellModuleRoute

Navegação com múltiplas pilhas independentes por branch. Cada branch preserva
seu próprio histórico de navegação. Internamente usa `StatefulShellRoute` do GoRouter.

```dart
statefulShell(
  builder: (context, state, shell) => BottomBarWidget(shell: shell),
  routes: [
    module(module: HomeModule()),
    module(module: ProfileModule()),
    module(module: FavoritesModule()),
  ],
  key: shellKey,              // opcional — GlobalKey<StatefulNavigationShellState>
  parentNavigatorKey: rootKey, // opcional
)
```

**Navegação entre branches:**

```dart
// No BottomBarWidget
shell.goBranch(index);   // StatefulNavigationShell.goBranch()
```

### CAP-RTE-07: DSL (mixin IDsl)

O mixin `IDsl` é incluído em todos os módulos e expõe os seguintes métodos:

| Método DSL | Classe criada | Path default |
|---|---|---|
| `child({required child, path?, ...})` | `ChildRoute` | `'/'` |
| `module({required module, name?, ...})` | `ModuleRoute` | `'/'` |
| `alias({required from, required to})` | `AliasRoute` | — |
| `shell({required routes, required builder, ...})` | `ShellModuleRoute` | — |
| `statefulShell({required routes, required builder, ...})` | `StatefulShellModuleRoute` | — |

### CAP-RTE-08: Transições

Sete transições built-in via `TypeTransition`:

| Enum | Animação |
|---|---|
| `fade` | Cross-fade (padrão) |
| `scale` | Zoom in |
| `slideUp` | De baixo para cima |
| `slideDown` | De cima para baixo |
| `slideLeft` | Da direita para esquerda |
| `slideRight` | Da esquerda para direita |
| `rotation` | Rotação |

Hierarquia de prioridade: `transition` na rota > `pageTransition` global > `fade`

### CAP-RTE-09: Navegação imperativa

Para contextos sem `BuildContext`:

```dart
modugoNavigatorKey.currentState?.push(...);
modugoNavigatorKey.currentContext   // BuildContext global
```

---

## Restrições

- Paths devem ser válidos conforme `path_to_regexp` — parâmetros com `:param`
- `AliasRoute` não funciona para rotas de módulos ou shell
- `ModuleRoute` sempre usa path `'/'` na DSL — o path é definido pelo módulo pai ao compor as rotas
- Paths com espaços ou parênteses inválidos lançam `FormatException` via `CompilerRoute`

---

## Casos de teste obrigatórios

- [ ] `Modugo.configure()` retorna o mesmo router em chamadas repetidas
- [ ] `ChildRoute` renderiza o widget correto para o path
- [ ] `ModuleRoute` ativa os binds do sub-módulo
- [ ] `AliasRoute` renderiza o mesmo widget que a rota original
- [ ] `AliasRoute` não aceita `ModuleRoute` como destino
- [ ] `ShellModuleRoute` mantém o builder ao navegar entre filhos
- [ ] `StatefulShellModuleRoute` preserva estado de cada branch ao trocar
- [ ] Transição por rota tem precedência sobre transição global
- [ ] Guard de rota bloqueia acesso e redireciona
