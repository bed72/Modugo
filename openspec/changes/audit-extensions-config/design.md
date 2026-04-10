## Context

Quatro fixes independentes e localizados. O mais delicado é o timing do `RouteChangedEventModel`
(escolha entre `microtask` e `addPostFrameCallback`) e a verificação de context em `reload()`
(BuildContext não expõe `mounted` — só `State` tem esse getter).

## Goals / Non-Goals

**Goals:**
- Corrigir os 4 problemas sem breaking changes
- `isKnownPath` passa a ser consistente com `matchingRoute` (ambos usam CompilerRoute)

**Non-Goals:**
- Alterar a API pública de `isKnownPath`, `reload`, ou `configure`
- Mudar o contrato de `RouteChangedEventModel` (continua emitindo location string)
- Tratar casos avançados de `redirectLimit` (ex: detecção de loop real)

## Decisions

### D1: `redirectLimit` de 2 → 12

**Escolhido:** 12 como novo default.

**Alternativa:** 100 (default do GoRouter).

**Rationale:** 100 mascara loops infinitos em desenvolvimento. 12 é conservador e cobre
cenários reais: auth guard → role guard → onboarding guard → redirect para destino são
~4 hops, com margem de 3x. Desenvolvedores com fluxos mais complexos podem aumentar via
parâmetro `redirectLimit` do `configure()`.

### D2: `_matchPath` usa `CompilerRoute.match()` em vez de `==`

**Escolhido:** `CompilerRoute(route.path).match(path)`.

**Rationale:** `CompilerRoute` já encapsula a lógica de `path_to_regexp` usada pelo GoRouter.
Usar a mesma infraestrutura garante consistência entre `isKnownPath` e `matchingRoute`. A
construção de `CompilerRoute` por chamada tem custo baixo — `match()` é O(n) do regexp.

**Risco:** `CompilerRoute` pode lançar `FormatException` para paths inválidos. Mitigação:
envolver em try/catch e retornar `false` (path inválido não é uma rota conhecida).

### D3: `reload()` com try/catch em vez de verificação de `mounted`

**Escolhido:** try/catch ao redor de `GoRouterState.of(this)` que captura `FlutterError`.

**Rationale:** `BuildContext` não tem getter `mounted` — esse getter existe em `State<T>`.
A extensão opera sobre `BuildContext`, então a única opção segura é try/catch. `GoRouterState.of`
lança `FlutterError` quando o context não tem um GoRouter ancestor ou está desmontado. Absorver
esse erro e logar via `Logger.warn` é o comportamento correto.

### D4: `RouteChangedEventModel` via `Future.microtask`

**Escolhido:** `Future.microtask(() => Event.emit(RouteChangedEventModel(current)))`.

**Alternativa:** `WidgetsBinding.instance.addPostFrameCallback(...)`.

**Rationale:** `addPostFrameCallback` só dispara se houver um frame agendado — em navegações
programáticas (testes, deep links sem UI ativa) pode nunca disparar. `Future.microtask` é
garantido: executa após o microtask atual completar, antes do próximo frame, e funciona em
todos os contextos incluindo testes. É a forma mais leve de defer sem dependência de frames.

## Risks / Trade-offs

- **`CompilerRoute` em `_matchPath` tem custo por chamada** → Aceitável. `isKnownPath` não
  é chamado em hot paths (redirect loop ou animação).

- **`RouteChangedEventModel` via microtask chega levemente depois** → Aceitável. A diferença
  é imperceptível para humanos. Listeners que assumiam dispatch síncrono terão que aguardar
  o próximo tick — o que é semanticamente mais correto.

## Migration Plan

Sem breaking changes. Nenhuma ação necessária para consumidores.

## Open Questions

Nenhuma.
