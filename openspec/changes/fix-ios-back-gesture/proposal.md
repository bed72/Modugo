## Why

`CustomTransitionPage` — usado em todos os `GoRoute.pageBuilder` do Modugo — não inclui
`CupertinoRouteTransitionMixin`, o que faz o gesto de swipe-back do iOS (deslizar da borda
esquerda para voltar) nunca ser instalado. Toda navegação feita pelo Modugo é afetada,
independente do tipo de transição configurada, degradando a experiência nativa iOS.

## What Changes

- **BREAKING (comportamento visual iOS)**: Por default, rotas iOS passam a usar `CupertinoPage`
  (slide nativo + back swipe), substituindo o `CustomTransitionPage(fade)` anterior.
- Novo valor `TypeTransition.native` no enum — seleciona `CupertinoPage` no iOS e
  `MaterialPage` no Android/outros de forma explícita e declarativa.
- Novo parâmetro `enableIOSGestureNavigation: bool` em `Modugo.configure()` — controle
  global (default `true`).
- Novo campo `iosGestureEnabled: bool?` em `ChildRoute` — override por rota (null herda global).
- `iosGestureEnabled` exposto no método `child()` do mixin `IDsl`.
- `FactoryRoute._transition()` atualizado com lógica de seleção de página por plataforma.

## Capabilities

### New Capabilities

- `ios-gesture-navigation`: Controle de gesto de back swipe no iOS com seleção
  adaptativa de tipo de página (`CupertinoPage` vs `CustomTransitionPage`).

### Modified Capabilities

- `routing`: Comportamento de `_transition()` muda — adiciona lógica de plataforma
  e novo valor de enum. CAP-RTE-01 (configure params), CAP-RTE-07 (DSL), CAP-RTE-08
  (transições) e novo CAP-RTE-10 (iOS gesture) são afetados.

## Impact

**Arquivos modificados:**
- `lib/src/transition.dart` — novo valor `native` no enum
- `lib/src/modugo.dart` — parâmetro + getter `enableIOSGestureNavigation`
- `lib/src/routes/child_route.dart` — campo `iosGestureEnabled: bool?`
- `lib/src/mixins/dsl_mixin.dart` — `iosGestureEnabled` em `child()`
- `lib/src/routes/factory_route.dart` — lógica de plataforma em `_transition()`

**Novos imports:**
- `package:flutter/cupertino.dart` em `factory_route.dart`
- `package:flutter/foundation.dart` em `factory_route.dart`

**Testes afetados:**
- `test/transition_test.dart` — `hasLength(7)` → `hasLength(8)`
- `test/routes/routes_factory_test.dart` — novos casos
- `test/routes/child_route_test.dart` — novos casos
- `test/modugo_test.dart` — novos casos

**Novo arquivo de teste:**
- `test/routes/factory_route_ios_test.dart` — testes dedicados ao comportamento iOS
