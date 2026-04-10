## MODIFIED Requirements

### Requirement: propagateGuards() propaga guards para todos os tipos de rota
`propagateGuards()` SHALL propagar guards herdados para `ChildRoute`, `ModuleRoute`,
`ShellModuleRoute`, `StatefulShellModuleRoute` **e `AliasRoute`** dentro de qualquer
nível de aninhamento. `AliasRoute` dentro de `StatefulShellModuleRoute` ou `ShellModuleRoute`
SHALL receber os guards propagados sem ser descartada silenciosamente.

#### Scenario: propagateGuards propaga para AliasRoute dentro de StatefulShellModuleRoute
- **WHEN** `propagateGuards(guards: [AuthGuard()], routes: [statefulShellWithAlias])` é chamado
- **THEN** o `AliasRoute` dentro do `StatefulShellModuleRoute` não é descartado
- **THEN** a rota alias está presente na árvore de rotas compilada

#### Scenario: propagateGuards propaga para AliasRoute dentro de ShellModuleRoute
- **WHEN** `propagateGuards(guards: [AuthGuard()], routes: [shellWithAlias])` é chamado
- **THEN** o `AliasRoute` dentro do `ShellModuleRoute` não é descartado
- **THEN** a rota alias está presente na árvore de rotas compilada
