## Why

Auditoria do repositório identificou 6 problemas no sistema de roteamento e guards. Dois são
bugs silenciosos que afetam guards em production (AliasRoute não propaga guards herdados dentro
de StatefulShell; ShellModuleRoute sem suporte a guards próprios). Dois são problemas de
observabilidade e robustez em testes (_pendingGuards não resetado; módulo skipped sem aviso).
Um é double-bind em configureRoutes() chamado múltiplas vezes. Um é mensagem de erro confusa
na AliasRoute. Todos têm zero breaking changes na API pública.

## What Changes

- Adicionar `FactoryRoute.resetForTesting()` que cancela e limpa `_pendingGuards`; chamá-lo em
  `Modugo.resetForTesting()` para garantir estado limpo entre testes
- Melhorar mensagem de `ArgumentError` em `_createAlias` para deixar explícito que AliasRoute
  só funciona com ChildRoute do mesmo módulo; atualizar docstring de `AliasRoute`
- Proteger `configureRoutes()` contra double-call na mesma instância usando `_routesConfigured`
  flag por instância (não por Type), prevenindo double-binds de IEvent
- Adicionar `Logger.warn` quando `_configureBinders` skipa um módulo por `runtimeType`
  já registrado, tornando o comportamento observável em dev
- Adicionar tratamento de `AliasRoute` no `map` de `StatefulShellModuleRoute.withInjectedGuards()`
  e verificar/corrigir o mesmo em `ShellModuleRoute.withInjectedGuards()`
- Adicionar campo `guards: List<IGuard>` opcional (default `const []`) em `ShellModuleRoute` e
  passar para `redirect` de `ShellRoute` em `_createShell` em `factory_route.dart`

## Capabilities

### New Capabilities

- `shell-route-guards`: `ShellModuleRoute` passa a aceitar `guards` no nível do shell,
  executados antes de qualquer rota filha ser renderizada

### Modified Capabilities

- `guards`: guards propagados via `propagateGuards()` agora alcançam `AliasRoute` dentro de
  `StatefulShellModuleRoute` e `ShellModuleRoute`
- `routing`: mensagem de erro de `AliasRoute` melhorada; `configureRoutes()` protegido contra
  double-call; `_pendingGuards` limpo em `resetForTesting()`

## Impact

- **`lib/src/routes/factory_route.dart`** — `resetForTesting()` adicionado; mensagem de erro
  melhorada em `_createAlias`; `redirect` de `ShellRoute` em `_createShell`
- **`lib/src/module.dart`** — flag `_routesConfigured` por instância; `Logger.warn` em skip
- **`lib/src/modugo.dart`** — `FactoryRoute.resetForTesting()` chamado em `resetForTesting()`
- **`lib/src/routes/shell_module_route.dart`** — campo `guards` adicionado
- **`lib/src/extensions/guard_extension.dart`** — `AliasRoute` tratado em ambas as extensões
  `ShellModuleRoute` e `StatefulShellModuleRoute`
- **API pública**: sem breaking changes — `guards` em `ShellModuleRoute` tem default `const []`
