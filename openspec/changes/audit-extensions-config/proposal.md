## Why

Quatro problemas de qualidade identificados na auditoria do repositório: o `redirectLimit` padrão
de 2 é insuficiente para apps reais com múltiplos guards de redirecionamento; `isKnownPath()` usa
comparação exata de strings em vez de regex, retornando `false` incorretamente para rotas com
path params; `reload()` não trata o caso de context inválido; e `RouteChangedEventModel` é emitido
sincronamente dentro do listener do GoRouter, antes de widgets reconstrúirem, podendo gerar
inconsistência para listeners que acessam o widget tree.

## What Changes

- Alterar o valor default de `redirectLimit` de `2` para `12` em `Modugo.configure()`
- Em `context_match_extension.dart`, substituir `route.path == path` por
  `CompilerRoute(route.path).match(path)` em `_matchPath()`, usando a mesma infraestrutura
  que `matchingRoute()` já utiliza corretamente
- Em `context_navigation_extension.dart`, envolver `reload()` em try/catch para absorver
  `FlutterError` quando `GoRouterState.of(this)` é chamado em context inválido, logando
  o erro em vez de propagar
- Em `lib/src/modugo.dart`, emitir `RouteChangedEventModel` via `Future.microtask` em vez
  de sincronamente dentro do `addListener` callback, garantindo que o evento chegue após
  o ciclo de build atual

## Capabilities

### New Capabilities

Nenhuma — todos os fixes são internos sem adição de API.

### Modified Capabilities

- `routing`: `redirectLimit` default aumentado; comportamento de `isKnownPath` corrigido para
  rotas com path params; `reload()` agora é tolerante a context inválido
- `events`: `RouteChangedEventModel` emitido após microtask em vez de sincronamente

## Impact

- **`lib/src/modugo.dart`** — default de `redirectLimit` e timing de `Event.emit`
- **`lib/src/extensions/context_match_extension.dart`** — `_matchPath()` usa `CompilerRoute`
- **`lib/src/extensions/context_navigation_extension.dart`** — `reload()` com try/catch
- **Sem breaking changes** — todos os fixes são internos ou ampliam comportamento correto
