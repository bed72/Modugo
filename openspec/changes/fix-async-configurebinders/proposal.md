## Why

`Module._configureBinders()` é declarado `async void` mas:
1. O chamador `configureRoutes()` não faz `await` — os binds rodam fire-and-forget
2. As chamadas recursivas para módulos importados também não têm `await`
3. Qualquer exceção dentro de `binds()` de um módulo importado é silenciosamente
   descartada pelo `async void` — o app continua sem a dependência registrada

Na prática, o `binds()` atual dos módulos não usa `await` interno, então não há
problema visível. O risco é latente: se qualquer módulo tentar usar `await` em
`binds()`, o comportamento será indefinido.

## What Changes

- Opção A: Tornar `binds()`, `imports()`, `configureRoutes()` e toda a cadeia
  `async` — breaking change, requer `await Modugo.configure()` (já é assim) e
  `await module.configureRoutes()`
- Opção B: Remover o `async` de `_configureBinders` já que não há nenhum `await`
  interno — low-risk, corrige o engano sem mudar a API
- Opção C: Documentar a limitação e adicionar aviso

**Recomendação: Opção B** — Remover `async` de `_configureBinders`. O método
não contém `await`, portanto o `async` é puramente enganoso. Se no futuro
`binds()` precisar ser async, isso deve ser tratado com uma proposta separada.

## Capabilities

### New Capabilities
- Nenhuma

### Modified Capabilities

- `module-system`: contrato de `_configureBinders` — deixa de ser fire-and-forget

## Impact

**Arquivos modificados:**
- `lib/src/module.dart` — remover `async` de `_configureBinders`

**Risco:** Mínimo — não há mudança de comportamento observável já que nenhum
`await` existe dentro do método. A diferença é que erros em `binds()` agora
propagam síncronamente para `configureRoutes()` em vez de serem silenciados.
