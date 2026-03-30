## MODIFIED Requirements

### Requirement: Execução sequencial de múltiplos guards
Múltiplos guards são executados em sequência dentro de uma `CancelableOperation`. O primeiro a
retornar um path não-nulo vence — os demais não são executados. Se a operação for cancelada
entre guards, a execução para e `null` é retornado.

#### Scenario: Primeiro guard com redirect vence, restante ignorado
- **WHEN** múltiplos guards estão configurados para uma rota
- **WHEN** o primeiro guard retorna um path não-nulo
- **THEN** os guards subsequentes não são executados
- **THEN** o path do primeiro guard é retornado

#### Scenario: Todos guards retornam null — navegação prossegue
- **WHEN** todos os guards de uma rota retornam `null`
- **THEN** `_executeGuards` retorna `null`
- **THEN** a navegação prossegue normalmente

#### Scenario: Cancelamento interrompe execução entre guards
- **WHEN** o primeiro guard completa com `null`
- **WHEN** uma nova navegação cancela a operação antes do segundo guard executar
- **THEN** o segundo guard não é invocado
- **THEN** `_executeGuards` retorna `null`
