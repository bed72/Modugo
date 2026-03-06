# 🔒 Guards

Os **Guards** no Modugo permitem controlar o acesso a rotas com base em condições lógicas, como autenticação, papéis de usuário ou verificações de sessão. Eles são executados **antes** do carregamento da rota e podem redirecionar o usuário conforme necessário.

---

## 🔹 Interface IGuard

Todo guard implementa a interface `IGuard`:

```dart
final class AuthGuard implements IGuard {
  final AuthRepository _repository;

  AuthGuard({required AuthRepository repository}) : _repository = repository;

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final isAuthenticated = await _repository.isAuthenticated();

    // Retorna null para permitir acesso
    // Retorna um path para redirecionar
    return isAuthenticated ? null : '/login';
  }
}
```

### Regras

- Retornar `null` → permite o acesso normalmente.
- Retornar uma `String` → redireciona o usuário para esse caminho.
- Guards suportam operações **assíncronas** (`FutureOr`).

---

## 🔹 Aplicando Guards em Rotas

Guards podem ser aplicados diretamente em `ChildRoute`:

```dart
route(
  '/dashboard',
  child: (_, _) => const DashboardPage(),
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
);
```

Ou usando a sintaxe tradicional:

```dart
ChildRoute(
  path: '/dashboard',
  child: (_, _) => const DashboardPage(),
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
);
```

---

## 🔹 Propagando Guards com `propagateGuards`

Quando você deseja aplicar um guard a **todas as rotas** de um módulo (incluindo submódulos), use `propagateGuards`:

```dart
final class AppModule extends Module {
  @override
  List<IRoute> routes() => propagateGuards(
    guards: [AuthGuard(repository: i.get<AuthRepository>())],
    routes: [
      module('/home', HomeModule()),
      module('/profile', ProfileModule()),
    ],
  );
}
```

Todas as rotas internas de `HomeModule` e `ProfileModule` herdam automaticamente o `AuthGuard`.

### Como funciona internamente

O `propagateGuards` percorre recursivamente as rotas e:

1. **ChildRoute** → os guards do pai são **prepended** aos guards da rota (executados primeiro).
2. **ModuleRoute** → o módulo é envolvido em um `GuardModuleDecorator` que injeta os guards em todas as suas rotas.
3. **ShellModuleRoute** → os guards são propagados para todas as rotas filhas.
4. **StatefulShellModuleRoute** → os guards são propagados para todas as branches.

---

## 🔹 Ordem de Execução

```
1. Guards propagados (do pai) → executados primeiro
2. Guards da rota atual → executados depois
3. Se todos retornarem null → navegação prossegue
4. Se algum retornar String → redirect para esse caminho
5. Redirect da rota (se definido) → avaliado após os guards
```

---

## 🔹 Tipos Comuns de Guard

### Guard de Autenticação

```dart
final class AuthGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await checkAuth();
    return isLoggedIn ? null : '/login';
  }
}
```

### Guard de Role/Permissão

```dart
final class AdminGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final user = context.read<UserService>().currentUser;
    return user.isAdmin ? null : '/unauthorized';
  }
}
```

### Guard com Side-Effect (sem redirect)

```dart
final class AnalyticsGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    Analytics.logPageView(state.uri.path);
    return null; // sempre permite acesso
  }
}
```

---

## 🔹 Exemplo Completo

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i
      ..registerSingleton<AuthRepository>(AuthRepositoryImpl())
      ..registerSingleton<UserService>(UserService());
  }

  @override
  List<IRoute> routes() => [
    // Rota publica (sem guard)
    route('/login', child: (_, _) => const LoginPage()),

    // Rotas protegidas
    ...propagateGuards(
      guards: [AuthGuard(repository: i.get<AuthRepository>())],
      routes: [
        route('/', child: (_, _) => const HomePage()),
        module('/profile', ProfileModule()),
        module('/admin', AdminModule()), // AdminModule pode ter seus proprios guards
      ],
    ),
  ];
}
```
