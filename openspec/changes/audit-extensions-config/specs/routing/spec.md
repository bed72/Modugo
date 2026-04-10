## MODIFIED Requirements

### Requirement: redirectLimit default é 12
O valor padrão do parâmetro `redirectLimit` em `Modugo.configure()` SHALL ser `12`.
Apps que precisam de mais redirects podem sobrescrever via parâmetro.

#### Scenario: Modugo.configure sem redirectLimit explícito usa 12
- **WHEN** `Modugo.configure(module: appModule)` é chamado sem `redirectLimit`
- **THEN** o GoRouter é configurado com `redirectLimit: 12`

### Requirement: isKnownPath reconhece rotas com path parameters
`context.isKnownPath(path)` SHALL retornar `true` quando o `path` fornecido corresponde a
uma rota existente com path parameters (ex: `/user/:id`), usando o mesmo mecanismo de matching
que `context.matchingRoute()`.

#### Scenario: isKnownPath retorna true para path que casa com rota parametrizada
- **WHEN** existe `ChildRoute(path: '/user/:id', ...)`
- **WHEN** `context.isKnownPath('/user/42')` é chamado
- **THEN** retorna `true`

#### Scenario: isKnownPath retorna false para path que não casa com nenhuma rota
- **WHEN** não existe rota para `/nonexistent/42`
- **WHEN** `context.isKnownPath('/nonexistent/42')` é chamado
- **THEN** retorna `false`

#### Scenario: isKnownPath continua funcionando para rotas estáticas
- **WHEN** existe `ChildRoute(path: '/settings', ...)`
- **WHEN** `context.isKnownPath('/settings')` é chamado
- **THEN** retorna `true`

### Requirement: reload() é tolerante a context inválido
`context.reload()` SHALL absorver `FlutterError` quando o context não é válido (sem GoRouter
ancestor ou widget desmontado), logando o erro sem propagar exceção.

#### Scenario: reload() com context válido navega para a rota atual
- **WHEN** o context é válido e possui GoRouter ancestor
- **WHEN** `context.reload()` é chamado
- **THEN** `goRouter.go(currentUri)` é executado normalmente

#### Scenario: reload() com context inválido não propaga FlutterError
- **WHEN** `GoRouterState.of(context)` lança `FlutterError`
- **WHEN** `context.reload()` é chamado
- **THEN** nenhuma exceção é propagada ao caller
