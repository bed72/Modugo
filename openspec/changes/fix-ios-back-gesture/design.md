## Context

`FactoryRoute._transition()` (factory_route.dart:395-427) é o único ponto onde páginas
são criadas em todo o Modugo. Atualmente retorna sempre `CustomTransitionPage`, que cria
internamente `_CustomTransitionPageRoute extends PageRouteBuilder<T>`. Este não herda
`CupertinoRouteTransitionMixin`, portanto nunca instala o `_CupertinoBackGestureDetector`
responsável pelo swipe-back no iOS.

`CupertinoPage.createRoute()` retorna `CupertinoPageRoute` que inclui
`CupertinoRouteTransitionMixin` e instala o gesture recognizer automaticamente.

A detecção de plataforma usa `defaultTargetPlatform` de `package:flutter/foundation.dart`,
que pode ser sobrescrito em testes via `debugDefaultTargetPlatformOverride`.

## Goals / Non-Goals

**Goals:**
- Gestos de back swipe iOS funcionam por default em todas as rotas Modugo
- Controle global via `Modugo.configure(enableIOSGestureNavigation:)`
- Override por rota via `ChildRoute(iosGestureEnabled:)` e DSL `child(iosGestureEnabled:)`
- Novo `TypeTransition.native` para seleção explícita de página nativa por plataforma
- Comportamento não-iOS inalterado
- Totalmente testável via `debugDefaultTargetPlatformOverride`

**Non-Goals:**
- Preservar animações customizadas no iOS enquanto o back swipe está ativo
  (requereria subclasse de `CupertinoPageRoute` com `transitionsBuilder` customizado —
  dependeria de internals do Flutter; fora de escopo nesta versão)
- Suporte a back swipe em `ShellModuleRoute` ou `StatefulShellModuleRoute` via
  builders próprios (esses usam `builder:`, não `pageBuilder:`)

## Decisions

### D1: Ponto único de mudança em `_transition()`

**Decisão:** Toda a lógica de seleção de página fica em `_transition()`.

**Rationale:** `_transition()` já é o único ponto de criação de páginas para
`ChildRoute`, `ModuleRoute` e `StatefulShellModuleRoute`. Centralizar a lógica
aqui evita duplicação e garante cobertura total.

**Alternativa rejeitada:** Modificar cada builder individualmente (`_createChild`,
`_createModule`, etc.) — maior superfície de mudança e risco de inconsistência.

### D2: Hierarquia de precedência

**Decisão:**
```
1. transition == TypeTransition.native  →  CupertinoPage (iOS) / MaterialPage (outros)
2. iosGestureEnabled != null           →  usa valor explícito da rota
3. Modugo.enableIOSGestureNavigation   →  usa valor global
4. plataforma == iOS + sem transition  →  CupertinoPage
5. caso contrário                      →  CustomTransitionPage (comportamento atual)
```

**Rationale:** Específico tem precedência sobre geral. `TypeTransition.native` é
sempre explícito. Override por rota tem precedência sobre global.
Quando `iosGestureEnabled: false` explícito, o usuário quer `CustomTransitionPage`
mesmo no iOS (ex: rota com animação customizada intencional).

### D3: `enableIOSGestureNavigation` como static getter no Modugo

**Decisão:** Armazenar em `static bool _enableIOSGestureNavigation` e expor via
`static bool get enableIOSGestureNavigation`.

**Rationale:** Mesmo padrão já usado por `_transition` e `getDefaultTransition`
no `Modugo`. Consistente com a API existente.

### D4: `iosGestureEnabled: bool?` com null semântico

**Decisão:** `null` significa "herde o global". `true`/`false` são overrides
explícitos.

**Rationale:** Permite adicionar o campo sem quebrar `ChildRoute`s existentes
(que ficam com `null` e herdam o default `true` do global).

## Risks / Trade-offs

**[Mudança visual iOS]** → Mitigação: documentar claramente no CHANGELOG que o default
muda de `CustomTransitionPage(fade)` para `CupertinoPage(slide nativo)`. Usuários que
precisam manter o comportamento anterior configuram `enableIOSGestureNavigation: false`.

**[CustomTransitionPage sem back swipe quando iosGestureEnabled: false]** → Mitigação:
`Logger.warn()` quando `enableIOSGestureNavigation: false` em iOS para alertar o
desenvolvedor. Documentar limitação na spec.

**[`debugDefaultTargetPlatformOverride` em testes]** → Mitigação: cada test group que
override a plataforma DEVE fazer `tearDown` resetando para `null`. Fakes do projeto
já existem em `test/fakes/fakes.dart` — manter o padrão.

## Migration Plan

1. Sem migração de dados necessária
2. Usuários que dependem do comportamento visual atual em iOS (fade) devem adicionar
   `Modugo.configure(enableIOSGestureNavigation: false)` ou definir um `pageTransition`
   explícito diferente de `TypeTransition.native`
3. `TypeTransition.values.length` muda de 7 para 8 — qualquer código que faz
   exhaustive check no enum precisará adicionar o caso `native`

## Open Questions

- Nenhuma. Escopo, design e tradeoffs foram discutidos e aprovados antes da implementação.
