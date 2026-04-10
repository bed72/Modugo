## ADDED Requirements

### Requirement: ShellModuleRoute aceita guards no nível do shell
`ShellModuleRoute` SHALL aceitar um campo opcional `guards: List<IGuard>` (default `const []`).
Quando fornecido, os guards são executados pelo `redirect` do `ShellRoute` antes de qualquer
rota filha ser renderizada.

#### Scenario: Guard no shell permite navegação quando retorna null
- **WHEN** `ShellModuleRoute` é criado com um guard que retorna `null`
- **WHEN** uma rota filha é acessada
- **THEN** o guard é executado e a navegação prossegue normalmente

#### Scenario: Guard no shell redireciona quando retorna path
- **WHEN** `ShellModuleRoute` é criado com um guard que retorna `'/login'`
- **WHEN** uma rota filha é acessada
- **THEN** o guard é executado e a navegação é redirecionada para `'/login'`

#### Scenario: ShellModuleRoute sem guards funciona idêntico ao comportamento anterior
- **WHEN** `ShellModuleRoute` é criado sem o campo `guards` (ou com `guards: const []`)
- **THEN** o `redirect` do `ShellRoute` gerado é `null`
- **THEN** comportamento é idêntico ao antes desta mudança
