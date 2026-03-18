# 🗺 Rotas

No Modugo, a navegação é baseada em GoRouter, oferecendo integração avançada com deep links e um ecossistema rico em extensões e utilidades. Isso permite organizar a UI em páginas, módulos e áreas específicas, mantendo pilhas de navegação independentes e preservação de estado de forma natural.

---

## 🔹 Tipos de Rotas

### ChildRoute

Representa uma rota simples dentro de um módulo ou página.

```dart
ChildRoute(
  path: '/home',
  child: (context, state) => const HomePage(),
)
```

#### Parâmetros

| Parâmetro | Tipo | Default | Descrição |
|-----------|------|---------|-----------|
| `path` | `String` | **obrigatório** | Caminho da rota |
| `child` | `Widget Function(BuildContext, GoRouterState)` | **obrigatório** | Widget da página |
| `name` | `String?` | `null` | Nome único da rota |
| `transition` | `TypeTransition?` | `null` | Transição da rota (herda a global se omitido) |
| `guards` | `List<IGuard>` | `[]` | Guards aplicados à rota |
| `parentNavigatorKey` | `GlobalKey<NavigatorState>?` | `null` | Chave do navigator pai |
| `pageBuilder` | `Page Function(BuildContext, GoRouterState)?` | `null` | Builder customizado de página |
| `onExit` | `FutureOr<bool> Function(...)?` | `null` | Callback ao sair da rota |
| `iosGestureEnabled` | `bool?` | `null` | Controla o swipe-back no iOS. Ver seção abaixo. |

#### Navegação iOS (swipe-back)

O parâmetro `iosGestureEnabled` permite controlar o gesto de swipe-back nativo do iOS por rota individualmente:

| Valor | Comportamento |
|-------|--------------|
| `null` (padrão) | Herda `Modugo.enableIOSGestureNavigation` (global, default `true`) |
| `true` | Força `CupertinoPage` nessa rota — swipe-back ativado |
| `false` | Desativa o swipe-back nessa rota |

> **Nota:** Ignorado quando `transition` é `TypeTransition.native`, que sempre usa a página nativa da plataforma.

```dart
// Desativa o swipe-back apenas nessa rota (ex: fluxo de checkout)
ChildRoute(
  path: '/checkout',
  child: (context, state) => const CheckoutPage(),
  iosGestureEnabled: false,
)

// Força swipe-back mesmo que o global esteja desativado
ChildRoute(
  path: '/details',
  child: (context, state) => const DetailsPage(),
  iosGestureEnabled: true,
)
```

Para definir o comportamento padrão de todo o app, use o parâmetro global em `Modugo.configure()`:

```dart
await Modugo.configure(
  module: AppModule(),
  enableIOSGestureNavigation: false, // desativa para todas as rotas por padrão
);
```

### ModuleRoute

Representa um módulo inteiro como rota.

```dart
ModuleRoute(
  path: '/profile',
  module: ProfileModule(),
)
```

### ShellModuleRoute

Use `ShellModuleRoute` quando quiser criar uma **área de navegação interna**, semelhante ao `RouteOutlet` do Flutter Modular. Ideal para layouts com menus ou abas, onde apenas parte da tela muda.

ℹ️ Internamente, utiliza `GoRouter`'s `ShellRoute`.

```dart
final class HomeModule extends Module {
  @override
  List<IRoute> routes() => [
    ShellModuleRoute(
      builder: (context, state, child) => PageWidget(child: child),
      routes: [
        ChildRoute(path: '/user', child: (_, _) => const UserPage()),
        ChildRoute(path: '/config', child: (_, _) => const ConfigPage()),
        ChildRoute(path: '/orders', child: (_, _) => const OrdersPage()),
      ],
    ),
  ];
}
```

### StatefulShellModuleRoute

Ideal para navegação baseada em **abas**, preservando o estado de cada aba.

✅ Benefícios:

- Cada aba possui sua própria pilha de navegação.
- Trocar de aba preserva histórico e estado.
- Integração completa com módulos Modugo, incluindo guards e ciclo de vida.

🎯 Casos de uso:

- Navegação inferior com abas independentes (Home, Profile, Favorites)
- Painéis administrativos ou dashboards com navegação persistente
- Apps tipo Instagram, Twitter ou apps bancários com fluxos empilhados separados

💡 Funcionamento:
Internamente, utiliza `StatefulShellRoute` do GoRouter. Cada `ModuleRoute` se torna uma **branch independente** com sua própria pilha de rotas.

```dart
StatefulShellModuleRoute(
  builder: (context, state, shell) => BottomBarWidget(shell: shell),
  routes: [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
    ModuleRoute(path: '/favorites', module: FavoritesModule()),
  ],
)
```

### Shell Page Example

```dart
class PageWidget extends StatelessWidget {
  final Widget child;

  const PageWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.person), onPressed: () => context.go('/user')),
              IconButton(icon: const Icon(Icons.settings), onPressed: () => context.go('/config')),
              IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => context.go('/orders')),
            ],
          ),
        ],
      ),
    );
  }
}
```

✅ Excelente para sub-navegação dentro de páginas
🎯 Útil para dashboards, painéis administrativos ou UIs multi-seção

---

## 🔹 AliasRoute

O `AliasRoute` funciona como um **apelido** para uma `ChildRoute` existente. Ele permite que múltiplos caminhos apontem para a mesma tela, sem duplicar lógica ou causar loops de redirecionamento.

```dart
final class ShopModule extends Module {
  @override
  List<IRoute> routes() => [
    route('/order/:id', child: (_, state) =>
      OrderPage(id: state.pathParameters['id']!)),

    alias(from: '/cart/:id', to: '/order/:id'),
  ];
}
```

Tanto `/order/123` quanto `/cart/123` renderizam a mesma `OrderPage`.

### Quando usar

- Compatibilidade retroativa com URLs antigas.
- Múltiplos caminhos semânticos para a mesma tela (ex: `/cart` e `/order`).

### Limitações

- Funciona **apenas para `ChildRoute`** (não para `ModuleRoute` ou `ShellModuleRoute`).
- O alias deve apontar para uma `ChildRoute` **existente dentro do mesmo módulo**.
- Não há suporte a alias encadeados.

### Vantagens sobre RedirectRoute

- Evita loops infinitos comuns em redirecionamentos.
- Mantém o historico de navegacao intacto.

---

## 🔹 Tipos de Rotas Suportadas

| Tipo | Uso |
|------|-----|
| `ChildRoute` | Telas simples |
| `ModuleRoute` | Submódulos |
| `AliasRoute` | Caminhos alternativos |
| `ShellModuleRoute` | Containers e layouts compartilhados |
| `StatefulShellModuleRoute` | Navegação com múltiplas pilhas |

> Para a API declarativa (DSL) com `route()`, `module()`, `alias()`, `shell()` e `statefulShell()`, consulte [API Declarativa (DSL)](dsl.md).

> Para transições de página, consulte [Transições](transitions.md).

---
