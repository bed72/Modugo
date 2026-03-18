## 1. BUG-6 — ShellModuleRoute builder force-unwrap

- [ ] 1.1 `factory_route.dart` `_createShell`: substituir `route.builder!(...)` por check + throw
- [ ] 1.2 Atualizar `test/routes/shell_module_null_builder_test.dart`: verificar que `ArgumentError` é lançado quando builder é null

## 2. BUG-ONEXIT — ChildRoute.onExit não encaminhado

- [ ] 2.1 `factory_route.dart` `_createChild`: adicionar `onExit: route.onExit` no GoRoute
- [ ] 2.2 Atualizar `test/routes/child_route_onexit_test.dart`: remover `[BUG-ONEXIT]` e verificar que onExit é invocado

## 3. BUG-12 — withInjectedGuards descarta key

- [ ] 3.1 `guard_extension.dart`: adicionar `key: key` em `StatefulShellModuleRouteExtensions.withInjectedGuards`
- [ ] 3.2 Atualizar `test/guards/guard_extension_key_test.dart`: `[BUG-12]` deve agora assertar `isNotNull`

## 4. DESIGN-7 — hashCode não inclui runtimeType

- [ ] 4.1 `child_route.dart`: adicionar `runtimeType.hashCode` ao hashCode
- [ ] 4.2 `module_route.dart`: adicionar `runtimeType.hashCode` ao hashCode
- [ ] 4.3 `shell_module_route.dart`: adicionar `runtimeType.hashCode` ao hashCode
- [ ] 4.4 Verificar que `test/routes/route_model_hashcode_test.dart` continua passando

## 5. DESIGN-9 — getExtra unsafe cast

- [ ] 5.1 `go_router_state_extension.dart`: substituir `extra as T?` por `extra is T ? extra as T : null`
- [ ] 5.2 Atualizar `test/extensions/go_router_state_unsafe_cast_test.dart`:
  `[DESIGN-9]` deve agora assertar `isNull` em vez de `throwsA`

## 6. CI

- [ ] 6.1 Rodar `flutter test` — 0 falhas
- [ ] 6.2 Rodar `flutter analyze` — 0 issues
- [ ] 6.3 Rodar `dart format --set-exit-if-changed lib test` — 0 erros
