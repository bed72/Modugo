## 1. FactoryRoute.resetForTesting() e Modugo integration

- [x] 1.1 Em `lib/src/routes/factory_route.dart`, adicionar método estático `@visibleForTesting static void resetForTesting()` que chama `_pendingGuards?.cancel()` e define `_pendingGuards = null`
- [x] 1.2 Em `lib/src/modugo.dart`, adicionar chamada a `FactoryRoute.resetForTesting()` dentro de `resetForTesting()`

## 2. Mensagem de erro de AliasRoute

- [x] 2.1 Em `lib/src/routes/factory_route.dart`, no `orElse` de `_createAlias`, substituir a mensagem atual por uma que mencione explicitamente: "AliasRoute only works with ChildRoute defined directly in the same module. Path '${alias.to}' was not found."
- [x] 2.2 Atualizar docstring da classe `AliasRoute` em `lib/src/routes/alias_route.dart` para documentar que `to` deve referenciar um path de `ChildRoute` diretamente no mesmo módulo

## 3. configureRoutes() idempotente por instância

- [x] 3.1 Em `lib/src/module.dart`, adicionar campo de instância `bool _routesConfigured = false`
- [x] 3.2 Em `configureRoutes()`, adicionar guard no início: se `_routesConfigured` é `true`, retornar `FactoryRoute.from(routes())` sem chamar `_configureBinders()`; caso contrário, chamar `_configureBinders()` e setar `_routesConfigured = true`

## 4. Logger.warn para módulo skipped

- [x] 4.1 Em `lib/src/module.dart`, no bloco `if (_modulesRegistered.contains(targetBinder.runtimeType))`, substituir `Logger.module(... skipped ...)` por `Logger.warn('${targetBinder.runtimeType} already registered — skipping. If this is intentional, ensure both instances share the same configuration.')`

## 5. AliasRoute em withInjectedGuards

- [x] 5.1 Em `lib/src/extensions/guard_extension.dart`, na extensão `StatefulShellModuleRouteExtensions.withInjectedGuards()`, adicionar case explícito `if (route is AliasRoute) return route;` antes do `return route` final (tornando o comportamento explícito e documentado)
- [x] 5.2 Verificar `ShellModuleRouteExtensions.withInjectedGuards()` — usa `propagateGuards` que já passa `AliasRoute` corretamente via `_injectGuards` fallback; sem alteração necessária

## 6. Guards em ShellModuleRoute

- [x] 6.1 Em `lib/src/routes/shell_module_route.dart`, adicionar campo `final List<IGuard> guards` com default `const []` no construtor
- [x] 6.2 Guards não participam de equality/hashCode (documentado via campo explícito; equality não alterada)
- [x] 6.3 Em `lib/src/routes/factory_route.dart`, no método `_createShell`, adicionar `redirect: route.guards.isNotEmpty ? (context, state) => _executeGuards(context: context, state: state, guards: route.guards) : null` ao `ShellRoute`

## 7. Testes

- [x] 7.1 Teste: `Modugo.resetForTesting()` zera `_pendingGuards` — operação cancelada após reset não interfere em testes subsequentes
- [x] 7.2 Teste: `AliasRoute` com `to` inexistente lança `ArgumentError` com mensagem contendo o path e menção à limitação de escopo
- [x] 7.3 Teste: `configureRoutes()` chamado 2x na mesma instância com IEvent — `listen()` chamado apenas 1x (verificar com contador)
- [x] 7.4 Teste: `Logger.warn` emitido quando módulo com mesmo `runtimeType` é skipped (comportamento verificado: não lança exceção)
- [x] 7.5 Teste: `propagateGuards` com `AliasRoute` dentro de `StatefulShellModuleRoute` — alias presente na árvore compilada
- [x] 7.6 Teste: `propagateGuards` com `AliasRoute` dentro de `ShellModuleRoute` — alias presente na árvore compilada
- [x] 7.7 Teste: `ShellModuleRoute` com guard que retorna `null` — `redirect` do `ShellRoute` é não-nulo e retorna `null`
- [x] 7.8 Teste: `ShellModuleRoute` com guard que retorna path — `redirect` retorna o path esperado
- [x] 7.9 Teste: `ShellModuleRoute` sem guards — `redirect` do `ShellRoute` é `null` (comportamento anterior preservado)

## 8. Verificação

- [x] 8.1 Rodar `flutter test` completo — zero regressões
- [x] 8.2 Rodar `flutter analyze` — zero warnings
- [x] 8.3 Rodar `dart format --set-exit-if-changed lib test`
