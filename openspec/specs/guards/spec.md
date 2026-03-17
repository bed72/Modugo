# Spec: Guards

**ID:** guards
**Status:** stable
**Version:** 4.x

## Overview

Guards controlam o acesso a rotas antes do carregamento. Implementam `IGuard` e
retornam `null` (permite) ou um path `String` (redireciona). Suportam operações
síncronas e assíncronas. Podem ser aplicados por rota individualmente ou
propagados para toda uma árvore de rotas via `propagateGuards()`.

---

## Capacidades

### CAP-GRD-01: Interface IGuard

```dart
abstract class IGuard {
  FutureOr<String?> call(BuildContext context, GoRouterState state);
}
```

**Contrato:**
- Retornar `null` → permite o acesso à rota
- Retornar `String` → redireciona para esse path
- Suporta `Future<String?>` para verificações assíncronas (ex: chamada de API)
- Erros lançados dentro do guard são **capturados e logados** — a navegação é bloqueada

### CAP-GRD-02: Aplicação por rota

Guards são declarados diretamente na rota via parâmetro `guards`:

```dart
child(
  path: '/dashboard',
  child: (_, _) => const DashboardPage(),
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
)
```

Múltiplos guards são executados **em sequência**. O primeiro a retornar um path
não-nulo vence — os demais não são executados.

### CAP-GRD-03: propagateGuards()

Injeta guards em toda uma árvore de rotas recursivamente:

```dart
List<IRoute> routes() => propagateGuards(
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
  routes: [
    module(module: HomeModule()),
    module(module: ProfileModule()),
    child(path: '/public', child: (_, _) => const PublicPage()), // também recebe o guard
  ],
);
```

**Comportamento por tipo de rota:**

| Tipo | Comportamento |
|---|---|
| `ChildRoute` | Guards do pai são **prepended** (executados antes dos próprios) |
| `ModuleRoute` | Módulo é envolvido em `GuardModuleDecorator` que injeta os guards |
| `ShellModuleRoute` | Guards propagados para todas as rotas filhas |
| `StatefulShellModuleRoute` | Guards propagados para todas as branches |

### CAP-GRD-04: Ordem de execução

```
1. Guards propagados (pai)         → executados primeiro
2. Guards da rota atual            → executados após os do pai
3. Se todos null                   → navegação prossegue
4. Primeiro non-null               → redirect (restante ignorado)
5. redirect() da rota (se definido) → avaliado após guards
6. redirect global de Modugo.configure() → avaliado primeiro de tudo
```

### CAP-GRD-05: GuardModuleDecorator

Permite aplicar guards a um módulo **sem modificá-lo**:

```dart
GuardModuleDecorator(
  module: AdminModule(),
  guards: [AdminGuard()],
)
```

Útil para adicionar guards a módulos de terceiros ou shared modules.

### CAP-GRD-06: Padrões de guard

**Autenticação:**

```dart
final class AuthGuard implements IGuard {
  final AuthRepository _repository;
  AuthGuard({required AuthRepository repository}) : _repository = repository;

  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async {
    final isAuthenticated = await _repository.isAuthenticated();
    return isAuthenticated ? null : '/login';
  }
}
```

**Role/Permissão:**

```dart
final class AdminGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    final user = context.read<UserService>().currentUser;
    return user.isAdmin ? null : '/unauthorized';
  }
}
```

**Side-effect sem bloqueio (ex: analytics):**

```dart
final class AnalyticsGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    Analytics.logPageView(state.uri.path);
    return null; // nunca bloqueia
  }
}
```

### CAP-GRD-07: Acesso a dependências no guard

Guards têm acesso ao `BuildContext`, portanto podem usar `context.read<T>()`:

```dart
final class FeatureFlagGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    final flags = context.read<FeatureFlagService>();
    return flags.isEnabled('new-dashboard') ? null : '/legacy-dashboard';
  }
}
```

Alternativamente, guards podem receber dependências via construtor (preferido para
testabilidade):

```dart
final class AuthGuard implements IGuard {
  final AuthRepository _repo;
  const AuthGuard(this._repo);
  // ...
}
```

---

## Restrições

- Guards NÃO devem lançar exceções intencionais para controlar fluxo — usar return de path
- Guards com erros não tratados bloqueiam a navegação e logam o erro
- `propagateGuards()` retorna uma nova lista — não modifica a original
- `GoRouterState` disponível no guard contém o state da rota destino (antes de navegar)

---

## Casos de teste obrigatórios

- [ ] Guard retornando `null` permite acesso à rota
- [ ] Guard retornando path redireciona para esse path
- [ ] Guard assíncrono funciona corretamente
- [ ] Múltiplos guards: primeiro non-null vence, restante ignorado
- [ ] Guards propagados são executados **antes** dos guards da rota
- [ ] `propagateGuards` propaga para `ChildRoute`, `ModuleRoute`, `ShellModuleRoute`, `StatefulShellModuleRoute`
- [ ] Guard que lança exceção bloqueia navegação e não propaga a exceção
- [ ] `GuardModuleDecorator` aplica guards sem modificar o módulo original
