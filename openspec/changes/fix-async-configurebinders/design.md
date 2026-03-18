## Context

`module.dart:131`:
```dart
void _configureBinders({IBinder? binder}) async {
  ...
  for (final imported in targetBinder.imports()) {
    _configureBinders(binder: imported);  // sem await
  }
  targetBinder.binds();
  ...
}
```

O `async void` transforma o método em um "fire-and-forget" silencioso. Em Dart,
`async void` descarta o `Future` retornado — erros são roteados para o
`Zone.current.handleUncaughtError`, não para o chamador.

## Goals / Non-Goals

**Goals:**
- Remover `async` enganoso de `_configureBinders`
- Erros em `binds()` propagam síncronamente para `configureRoutes()`

**Non-Goals:**
- Tornar `binds()` async (proposta separada se necessário)
- Mudar a API pública

## Decisions

### D1: Remover `async` de `_configureBinders`

```dart
// Antes
void _configureBinders({IBinder? binder}) async { ... }

// Depois
void _configureBinders({IBinder? binder}) { ... }
```

Não há `await` no corpo do método, portanto a mudança é segura e sem risco de
regressão. O comportamento runtime é idêntico exceto pela propagação de erros.

## Risks / Trade-offs

**[Erros que antes eram silenciados agora propagam]** → Isso é o comportamento
correto. Se um `binds()` lançava uma exceção antes, ela era silenciada; agora
chegará como `StateError` ou `Exception` em `Modugo.configure()`.

## Migration Plan

1. Remover `async` de `void _configureBinders`
2. Rodar todos os testes — não deve haver regressões
3. O teste `test/modules/module_test.dart` de paths inválidos deve continuar passando
