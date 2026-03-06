# 🧰 Extensions

O Modugo fornece um conjunto de extensions no `BuildContext`, `GoRouterState` e `Uri` que enriquecem a navegação, injeção e manipulação de rotas.

---

## 🔹 ContextNavigationExtension

Simplifica operações de navegação com GoRouter diretamente no `BuildContext`.

### Métodos disponíveis

| Método | Descrição |
|--------|-----------|
| `go(location, {extra})` | Navega para o caminho |
| `goNamed(name, {pathParameters, queryParameters, extra, fragment})` | Navega por nome |
| `push(location, {extra})` | Empilha uma nova rota |
| `pushNamed(name, {pathParameters, queryParameters, extra})` | Empilha por nome |
| `pop([result])` | Remove a rota atual da pilha |
| `canPop()` | Verifica se pode voltar |
| `canPush(location)` | Verifica se o caminho existe no router |
| `replace(location, {extra})` | Substitui a rota atual |
| `pushReplacement(location, {extra})` | Empilha substituindo a atual |
| `replaceNamed(name, {pathParameters, queryParameters, extra})` | Substitui por nome |
| `pushReplacementNamed(name, {...})` | Empilha substituindo por nome |
| `reload()` | Recarrega a rota atual |
| `replaceStack(paths)` | Substitui toda a pilha de navegação |
| `goRouter` | Acessa a instância do GoRouter |

### Exemplos

```dart
// Navegação básica
context.go('/home');
context.push('/product/42');

// Navegação por nome
context.goNamed('product', pathParameters: {'id': '42'});
context.pushNamed('settings', queryParameters: {'tab': 'privacy'});

// Controle de pilha
if (context.canPop()) context.pop();

// Validação antes de navegar
if (context.canPush('/settings')) {
  context.go('/settings');
}

// Recarregar página atual
context.reload();

// Substituir toda a pilha
await context.replaceStack(['/home', '/profile', '/settings']);
```

---

## 🔹 ContextMatchExtension

Permite verificar rotas registradas, encontrar rotas correspondentes e extrair parâmetros.

### Métodos disponíveis

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `isKnownPath(path)` | `bool` | Verifica se o path está registrado |
| `isKnownRouteName(name)` | `bool` | Verifica se o nome da rota existe |
| `matchingRoute(location)` | `GoRoute?` | Retorna a rota correspondente |
| `matchParams(location)` | `Map<String, String>?` | Extrai parâmetros do path |
| `state` | `GoRouterState` | Acessa o state atual do GoRouter |

### Exemplos

```dart
// Validação de rotas
final isValid = context.isKnownPath('/settings');
final isNamed = context.isKnownRouteName('profile');

// Encontrar rota correspondente
final route = context.matchingRoute('/user/42');
if (route != null) {
  debugPrint('Rota encontrada: ${route.name}');
}

// Extrair parâmetros
final params = context.matchParams('/user/42');
final userId = params?['id']; // '42'
```

---

## 🔹 ContextInjectionExtension

Acesso a dependências registradas no GetIt via `BuildContext`.

### Métodos disponíveis

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `read<T>({param1, param2, type, instanceName})` | `T` | Recupera dependência síncrona |
| `readAsync<T>({param1, param2, type, instanceName})` | `Future<T>` | Recupera dependência assíncrona |

### Exemplos

```dart
// Acesso simples
final service = context.read<AuthService>();

// Instância nomeada
final db = context.read<Database>(instanceName: 'primary');

// Dependência assíncrona
final api = await context.readAsync<ApiClient>();
```

---

## 🔹 GoRouterStateExtension

Helpers para acessar dados do estado de navegação atual.

### Propriedades e métodos

| Membro | Retorno | Descrição |
|--------|---------|-----------|
| `getExtra<T>()` | `T?` | Extra passado na navegação, com cast |
| `isCurrentRoute(name)` | `bool` | Verifica se a rota atual tem o nome dado |
| `effectivePath` | `String` | Path do extra (se Map com 'path') ou uri.path |
| `isInitialRoute` | `bool` | `true` se `matchedLocation == '/'` |
| `locationSegments` | `List<String>` | Segmentos do path como lista |
| `getPathParam(param)` | `String?` | Valor de um parâmetro dinâmico do path |
| `getStringQueryParam(key)` | `String?` | Valor de query param como String |
| `getIntQueryParam(key)` | `int?` | Valor de query param como int |
| `getBoolQueryParam(key)` | `bool?` | Valor de query param como bool |
| `argumentsOrThrow<T>()` | `T` | Extra com cast obrigatório (throws se inválido) |

### Exemplos

```dart
// Extrair parâmetros
final id = state.getPathParam('id');
final page = state.getIntQueryParam('page');
final isActive = state.getBoolQueryParam('active');
final search = state.getStringQueryParam('q');

// Extras
final data = state.getExtra<MyModel>();
final required = state.argumentsOrThrow<MyModel>(); // throws se null

// Estado
if (state.isInitialRoute) {
  // Estamos na raiz
}

final segments = state.locationSegments;
// '/profile/settings' → ['profile', 'settings']
```

---

## 🔹 UriPathWithExtras

Extension no `Uri` com utilitários para manipulação de paths.

### Métodos disponíveis

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `fullPath` | `String` | Path completo com query e fragment |
| `hasQueryParam(key)` | `bool` | Verifica se query param existe |
| `getQueryParam(key, {defaultValue})` | `String?` | Valor do query param |
| `isSubPathOf(other)` | `bool` | Verifica se é sub-path de outro Uri |
| `withAppendedPath(subPath)` | `Uri` | Novo Uri com subpath concatenado |

### Exemplos

```dart
final uri = Uri.parse('/page?foo=1#section');

uri.fullPath;           // '/page?foo=1#section'
uri.hasQueryParam('foo'); // true
uri.getQueryParam('foo'); // '1'

final base = Uri.parse('/api');
uri.isSubPathOf(base);  // false

final extended = base.withAppendedPath('users');
// → Uri('/api/users')
```
