# Spec: Extensions

**ID:** extensions
**Status:** stable
**Version:** 4.x

## Overview

O Modugo fornece um conjunto de extensions em `BuildContext`, `GoRouterState`
e `Uri` que enriquecem a navegação, injeção e manipulação de rotas sem necessitar
acesso direto ao GoRouter ou GetIt.

---

## Capacidades

### CAP-EXT-01: ContextNavigationExtension

Operações de navegação GoRouter via `BuildContext`:

```dart
// Navegação básica
context.go('/home')
context.go('/product/:id', extra: {'data': value})
context.push('/details')
context.pop()
context.pop(result)     // pop com valor de retorno

// Por nome de rota
context.goNamed('home')
context.goNamed('product',
  pathParameters: {'id': '42'},
  queryParameters: {'tab': 'info'},
  extra: data,
  fragment: 'section',
)
context.pushNamed('settings', pathParameters: {}, queryParameters: {})

// Substituição
context.replace('/new-path')
context.pushReplacement('/new-path')
context.replaceNamed('name', pathParameters: {})
context.pushReplacementNamed('name', pathParameters: {})

// Verificações
context.canPop()                  // bool — se pode fazer pop
context.canPush('/settings')      // bool — se o path existe no router

// Utilitários
context.reload()                  // recarrega a rota atual (push da mesma rota)
await context.replaceStack(['/home', '/profile', '/settings'])  // substitui toda a pilha

// Acesso à instância
context.goRouter                  // GoRouter instance
```

### CAP-EXT-02: ContextMatchExtension

Inspeção de rotas registradas:

```dart
// Verificações
context.isKnownPath('/settings')          // bool — path existe no router
context.isKnownRouteName('profile')       // bool — rota nomeada existe

// Busca
context.matchingRoute('/user/42')         // GoRoute? — rota que faz match
context.matchParams('/user/42')           // Map<String, String>? — extrai params

// Estado atual
context.state                             // GoRouterState atual
```

Exemplo de uso:

```dart
// Validar antes de navegar
if (context.isKnownPath('/premium-feature')) {
  context.go('/premium-feature');
}

// Extrair params sem navegar
final params = context.matchParams('/user/42');
final userId = params?['id']; // '42'
```

### CAP-EXT-03: ContextInjectionExtension

Acesso a dependências GetIt via `BuildContext`:

```dart
// Síncrono
context.read<AuthService>()
context.read<Database>(instanceName: 'primary')
context.read<Widget>(param1: 'title', param2: 42)  // factory parametrizada

// Assíncrono (registerSingletonAsync)
await context.readAsync<ApiClient>()
await context.readAsync<ConfigService>(instanceName: 'remote')
```

**Parâmetros de `read<T>()` e `readAsync<T>()`:**

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `instanceName` | `String?` | Nome da instância registrada |
| `param1` | `dynamic` | 1º parâmetro para factory parametrizada |
| `param2` | `dynamic` | 2º parâmetro para factory parametrizada |
| `type` | `Type?` | Tipo específico para múltiplas implementações |

### CAP-EXT-04: GoRouterStateExtension

Helpers para extrair dados do estado de navegação atual:

```dart
// Parâmetros de path e query
state.getPathParam('id')               // String? — ':id' do path
state.getStringQueryParam('q')         // String? — '?q=value'
state.getIntQueryParam('page')         // int? — parse automático
state.getBoolQueryParam('active')      // bool? — 'true'/'false'

// Extras
state.getExtra<MyModel>()              // T? — cast com verificação de tipo
state.argumentsOrThrow<MyModel>()      // T — throws StateError se null ou tipo errado

// Estado da rota
state.effectivePath                    // String — path do extra['path'] ou uri.path
state.isInitialRoute                   // bool — matchedLocation == '/'
state.isCurrentRoute('route-name')     // bool — rota atual tem esse nome
state.locationSegments                 // List<String> — '/a/b' → ['a', 'b']
```

Exemplo completo em `child()`:

```dart
child(
  path: '/user/:id',
  child: (context, state) {
    final userId = state.getPathParam('id')!;
    final tab = state.getStringQueryParam('tab') ?? 'profile';
    final user = state.getExtra<UserModel>();
    return UserPage(userId: userId, tab: tab, user: user);
  },
)
```

### CAP-EXT-05: UriExtension

Utilitários para manipulação de `Uri`:

```dart
final uri = Uri.parse('/page?foo=1&bar=2#section');

uri.fullPath                              // '/page?foo=1&bar=2#section'
uri.hasQueryParam('foo')                  // true
uri.getQueryParam('foo')                  // '1'
uri.getQueryParam('missing', defaultValue: 'x')  // 'x'

final base = Uri.parse('/api/v1');
uri.isSubPathOf(base)                     // false
base.withAppendedPath('users')            // Uri('/api/v1/users')
base.withAppendedPath('/users')           // Uri('/api/v1/users') — normaliza barra
```

---

## Restrições

- `context.canPush()` requer que o `BuildContext` tenha acesso ao GoRouter configurado
- `context.readAsync<T>()` lança `StateError` se o tipo não for async singleton
- `state.argumentsOrThrow<T>()` lança `StateError` se `extra` for null ou tipo incompatível
- `Uri.withAppendedPath()` normaliza barras duplicadas automaticamente
- `replaceStack()` é assíncrono — navega em sequência programaticamente

---

## Casos de teste obrigatórios

- [ ] `context.go()` navega para o path correto
- [ ] `context.push()` empilha a rota sem descartar a atual
- [ ] `context.pop()` retorna para a rota anterior
- [ ] `context.canPop()` retorna false quando não há rotas anteriores
- [ ] `context.canPush('/invalid')` retorna false para paths inexistentes
- [ ] `context.isKnownPath()` detecta paths registrados
- [ ] `context.matchParams()` extrai parâmetros corretamente
- [ ] `context.read<T>()` resolve dependência registrada
- [ ] `state.getPathParam()` retorna valor do parâmetro dinâmico
- [ ] `state.getIntQueryParam()` converte string para int
- [ ] `state.argumentsOrThrow<T>()` lança se extra é null
- [ ] `uri.withAppendedPath()` normaliza barras
