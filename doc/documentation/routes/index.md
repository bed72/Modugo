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

## 🔹 Roteamento com Regex

Modugo suporta **matchings de rotas poderosos** usando padrões regex.

- Valida caminhos e deep links antes da navegação
- Extrai parâmetros dinâmicos independentemente do GoRouter
- Suporta URLs externas, web e lógica de redirect personalizada

```dart
ChildRoute(
  path: '/user/:id',
  child: (_, _) => const UserPage(),
  routePattern: RoutePatternModel.from(r'^/user/(\d+)\$', paramNames: ['id']),
)

final match = Modugo.matchRoute('/user/42');
if (match != null) {
  print(match.route); // rota encontrada
  print(match.params); // { 'id': '42' }
} else {
  print('Nenhuma correspondência');
}
```

---

## 🔹 Tipos de Rotas Suportadas

- ChildRoute
- ModuleRoute
- ShellModuleRoute
- StatefulShellModuleRoute

### ⚡ Utilidades

- Analytics e logging
- Validação de deep links
- Rotas fallback e redirects

---

## 🔹 Extensões de Navegação

Modugo fornece extensões em BuildContext que enriquecem a navegação, oferecendo ferramentas para validação de rotas, extração de parâmetros e operações avançadas com GoRouter.

ContextMatchExtension

Permite:

Verificar se um caminho (path) ou nome de rota (name) está registrado.

Obter a rota correspondente para um dado local.

Extrair parâmetros dinâmicos de rotas.

💡 Útil para validação de links, navegação condicional e debugging de rotas.

Exemplo:

```dart
final isValid = context.isKnownPath('/settings');
final isNamed = context.isKnownRouteName('profile');

final matchedRoute = context.matchingRoute('/user/42');
final params = context.matchParams('/user/42');
final userId = params?['id'];
```

ContextNavigationExtension

Simplifica operações de navegação padrão com GoRouter:

- Métodos de navegação: `go, goNamed, push, pushNamed, replace`, etc.
- Controle de rota atual: `reload()` para recarregar a página.
- Validação de navegação: `canPop()` e `canPush()`.
- Gerenciamento de pilhas de navegação: `replaceStack()`.

💡 Facilita:

- Navegação dinâmica
- Integração com deep links e parâmetros
- Simplificação de operações complexas de roteamento

Exemplo:

```dart
context.go('/home');

context.pushNamed('product', pathParameters: {'id': '42'});

if (context.canPop()) context.pop();

context.reload();

await context.replaceStack(['/home', '/profile']);
```

✅ Essas extensões tornam o desenvolvimento de UIs complexas mais simples, seguro e organizado, integrando diretamente o GoRouter ao contexto de forma fluida.

---
