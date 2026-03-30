# Spec: Guard Concurrency Protection

**ID:** guard-concurrency-protection
**Status:** stable
**Version:** 4.x

## Overview

Protege a execução de guards contra condições de corrida causadas por navegações
concorrentes. Quando uma nova chamada a `_executeGuards` é iniciada enquanto uma
anterior ainda está pendente, a chamada anterior é supersedida — seu resultado é
descartado e `null` é retornado para ela. Apenas o resultado da chamada mais
recente é entregue ao GoRouter.

A implementação utiliza `CancelableOperation` (pacote `async`) para controlar o
ciclo de vida de cada execução de guards, sem interromper o `Future` subjacente.

---

## Capacidades

### Requirement: Cancelamento de execução supersedida de guards

Quando uma nova chamada a `_executeGuards` é iniciada enquanto uma chamada anterior ainda está
pendente, o sistema SHALL cancelar o recebimento do resultado da chamada anterior e retornar `null`
para ela, garantindo que apenas o resultado da chamada mais recente seja entregue ao GoRouter.

#### Scenario: Segunda navegação cancela resultado da primeira

- **WHEN** `_executeGuards` é chamado uma segunda vez antes da primeira chamada completar
- **THEN** a primeira chamada retorna `null` (sem redirect) ao resolver
- **THEN** a segunda chamada executa normalmente e retorna seu resultado

#### Scenario: Navegação única sem concorrência preserva resultado

- **WHEN** `_executeGuards` é chamado uma única vez e completa normalmente
- **THEN** o resultado do guard (null ou path de redirect) é retornado sem alteração

#### Scenario: Guard com redirect é cancelado por nova navegação

- **WHEN** um guard retornaria `/login` mas uma segunda chamada a `_executeGuards` chega antes
- **THEN** a primeira chamada retorna `null` em vez de `/login`
- **THEN** a segunda chamada executa seus próprios guards normalmente

#### Scenario: Múltiplas navegações encadeadas — apenas a última prevalece

- **WHEN** três ou mais chamadas a `_executeGuards` são iniciadas em sequência rápida
- **THEN** apenas a última chamada entrega seu resultado ao GoRouter
- **THEN** todas as chamadas anteriores retornam `null`

---

### Requirement: Trabalho async interno dos guards não é interrompido

O sistema SHALL NOT cancelar o `Future` subjacente do guard quando uma operação é supersedida —
apenas o recebimento do resultado é cancelado.

#### Scenario: Guard async continua executando após cancelamento

- **WHEN** uma `CancelableOperation` é cancelada
- **THEN** o `Future` passado para `fromFuture` executa até o fim
- **THEN** o resultado desse `Future` é simplesmente descartado

---

### Requirement: Guards com exceção em chamada cancelada não propagam erro

Quando uma chamada a `_executeGuards` é cancelada e o guard interno lança uma exceção,
o sistema SHALL retornar `null` em vez de relançar a exceção.

#### Scenario: Exceção em guard cancelado é absorvida

- **WHEN** um guard lança exceção durante uma chamada que foi cancelada por uma nova navegação
- **THEN** `_executeGuards` retorna `null` sem propagar a exceção

---

### Requirement: Guards com exceção em chamada ativa propagam erro normalmente

Quando não há cancelamento, o comportamento existente de log + rethrow SHALL ser preservado.

#### Scenario: Exceção em guard ativo é logada e relançada

- **WHEN** um guard lança exceção e não há chamada concorrente que cancele esta
- **THEN** o erro é logado via `Logger.error`
- **THEN** a exceção é relançada (rethrow)

---

## Restrições

- O cancelamento afeta apenas o recebimento do resultado — o `Future` do guard executa até o fim
- `CancelableOperation.fromFuture` é utilizado sem `cancelOnError: true` para preservar esse comportamento
- A operação cancelada anterior deve ser descartada antes de criar a nova operação

---

## Casos de teste obrigatórios

- [ ] Segunda navegação cancela resultado da primeira (primeira retorna `null`)
- [ ] Navegação única sem concorrência retorna resultado do guard sem alteração
- [ ] Guard com redirect é cancelado por nova navegação — retorna `null`
- [ ] Três navegações encadeadas — apenas a última retorna seu resultado
- [ ] Future subjacente do guard continua executando após cancelamento
- [ ] Exceção em guard cancelado é absorvida (retorna `null`, não propaga)
- [ ] Exceção em guard ativo é logada e relançada normalmente
