## 1. redirectLimit default

- [x] 1.1 Em `lib/src/modugo.dart`, alterar o valor padrão do parâmetro `redirectLimit` de `2` para `12`

## 2. isKnownPath com regex matching

- [x] 2.1 Em `lib/src/extensions/context_match_extension.dart`, no método `_matchPath()`, substituir `route.path == path` por um try/catch que usa `CompilerRoute(route.path).match(path)` — retornar `false` se `CompilerRoute` lançar `FormatException`
- [x] 2.2 Adicionar import de `CompilerRoute` no arquivo se ainda não presente

## 3. reload() tolerante a context inválido

- [x] 3.1 Em `lib/src/extensions/context_navigation_extension.dart`, envolver o corpo de `reload()` em try/catch que captura `FlutterError` e registra via `Logger.warn('context.reload() called on invalid context: $e')`

## 4. RouteChangedEventModel via microtask

- [x] 4.1 Em `lib/src/modugo.dart`, dentro do `routerDelegate.addListener` callback, substituir `Event.emit(RouteChangedEventModel(current))` por `Future.microtask(() => Event.emit(RouteChangedEventModel(current)))`

## 5. Testes

- [x] 5.1 Teste: `Modugo.configure()` sem `redirectLimit` explícito — verificar que GoRouter recebe `redirectLimit: 12` (via `modugoRouter.configuration.redirectLimit`)
- [x] 5.2 Teste: `isKnownPath('/user/42')` retorna `true` quando existe rota `/user/:id`
- [x] 5.3 Teste: `isKnownPath('/user/42')` retorna `false` quando não há rota matching
- [x] 5.4 Teste: `isKnownPath('/settings')` retorna `true` para rota estática (regressão)
- [x] 5.5 Teste: `isKnownPath('/bad path with spaces')` retorna `false` sem lançar exceção (path inválido para CompilerRoute)
- [x] 5.6 Teste: `RouteChangedEventModel` é emitido após microtask — spy no `routerDelegate.addListener` verifica que o evento não chegou sincronamente dentro do callback
- [x] 5.7 Teste: `RouteChangedEventModel` não é emitido quando location não muda (deduplicação preservada)

## 6. Verificação

- [x] 6.1 Rodar `flutter test` completo — zero regressões
- [x] 6.2 Rodar `flutter analyze` — zero warnings
- [x] 6.3 Rodar `dart format --set-exit-if-changed lib test`
