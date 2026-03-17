## 1. Enum e tipos base

- [ ] 1.1 Adicionar `native` ao enum `TypeTransition` em `lib/src/transition.dart`

## 2. Modugo.configure()

- [ ] 2.1 Adicionar campo `static bool _enableIOSGestureNavigation` ao `Modugo`
- [ ] 2.2 Adicionar getter `static bool get enableIOSGestureNavigation`
- [ ] 2.3 Adicionar parâmetro `enableIOSGestureNavigation: bool = true` ao `Modugo.configure()`

## 3. ChildRoute + DSL

- [ ] 3.1 Adicionar campo `iosGestureEnabled: bool?` ao `ChildRoute`
- [ ] 3.2 Atualizar construtor, `==` e `hashCode` do `ChildRoute`
- [ ] 3.3 Expor `iosGestureEnabled: bool?` no método `child()` do mixin `IDsl`

## 4. FactoryRoute — lógica central

- [ ] 4.1 Adicionar imports `flutter/cupertino.dart` e `flutter/foundation.dart` em `factory_route.dart`
- [ ] 4.2 Implementar lógica de precedência em `_transition()` conforme design.md D2

## 5. Testes — enum e transition

- [ ] 5.1 Atualizar `test/transition_test.dart`: `hasLength(7)` → `hasLength(8)`, adicionar `contains(TypeTransition.native)`

## 6. Testes — ChildRoute

- [ ] 6.1 Adicionar teste: `ChildRoute.iosGestureEnabled` é `null` por default
- [ ] 6.2 Adicionar teste: `ChildRoute` com `iosGestureEnabled: false` mantém equality correta

## 7. Testes — Modugo

- [ ] 7.1 Adicionar teste: `enableIOSGestureNavigation` é `true` por default após `configure()`
- [ ] 7.2 Adicionar teste: `Modugo.configure(enableIOSGestureNavigation: false)` persiste `false`

## 8. Testes — factory_route_ios (arquivo novo)

- [ ] 8.1 Criar `test/routes/factory_route_ios_test.dart` com helper `_override(platform)` / `_reset()`
- [ ] 8.2 Teste: `enableIOSGestureNavigation: true` (default) → `CupertinoPage` para `ChildRoute` sem transition em iOS
- [ ] 8.3 Teste: `enableIOSGestureNavigation: true` → `CupertinoPage` para `ModuleRoute` em iOS
- [ ] 8.4 Teste: `enableIOSGestureNavigation: false` → `CustomTransitionPage` em iOS
- [ ] 8.5 Teste: `ChildRoute(iosGestureEnabled: false)` sobrepõe global `true` → `CustomTransitionPage` em iOS
- [ ] 8.6 Teste: `ChildRoute(iosGestureEnabled: true)` sobrepõe global `false` → `CupertinoPage` em iOS
- [ ] 8.7 Teste: `ChildRoute` com `transition: TypeTransition.fade` → `CustomTransitionPage` mesmo com global `true` em iOS
- [ ] 8.8 Teste: `ChildRoute` com `transition: TypeTransition.slideLeft` → `CustomTransitionPage` em iOS
- [ ] 8.9 Teste: `TypeTransition.native` em iOS → `CupertinoPage`
- [ ] 8.10 Teste: `TypeTransition.native` em Android → `MaterialPage`
- [ ] 8.11 Teste: `StatefulShellModuleRoute` respeita `enableIOSGestureNavigation: true` em iOS
- [ ] 8.12 Teste: `enableIOSGestureNavigation: true` não afeta Android → `CustomTransitionPage`

## 9. Testes — routes_factory_test (casos novos)

- [ ] 9.1 Adicionar teste: `pageBuilder` com `TypeTransition.native` retorna `CupertinoPage` em iOS
- [ ] 9.2 Adicionar teste: `pageBuilder` com `TypeTransition.native` retorna `MaterialPage` em Android

## 10. Spec e CI

- [ ] 10.1 Atualizar `openspec/specs/routing/spec.md`: adicionar `enableIOSGestureNavigation` à tabela CAP-RTE-01 e novo CAP-RTE-10
- [ ] 10.2 Rodar `flutter test` — 0 falhas
- [ ] 10.3 Rodar `flutter analyze` — 0 warnings/errors
- [ ] 10.4 Rodar `dart format --set-exit-if-changed lib test` — 0 erros
