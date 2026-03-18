## Why

Quatro bugs de severidade média encontrados durante a auditoria da lib afetam
o comportamento em casos de uso comuns e violam contratos documentados:

- **BUG-6**: `ShellModuleRoute.builder` é nullable mas recebe force-unwrap `!` em
  `factory_route.dart` — crash se `builder: null` for passado explicitamente
- **BUG-12**: `StatefulShellModuleRoute.withInjectedGuards()` descarta o campo `key`
  — rotas que dependem de `GlobalKey<StatefulNavigationShellState>` estável perdem
  a chave após injeção de guards
- **DESIGN-7**: `ChildRoute.operator==` inclui `runtimeType` mas `hashCode` não —
  viola o contrato Dart `a == b ⟹ a.hashCode == b.hashCode` (mesmo problema em
  `ModuleRoute` e `ShellModuleRoute`)
- **DESIGN-9**: `getExtra<T>()` usa cast inseguro `extra as T?` — lança `TypeError`
  quando `extra` tem tipo errado em vez de retornar `null` como a doc sugere
- **BUG-ONEXIT**: `ChildRoute.onExit` nunca é passado ao `GoRoute` subjacente em
  `FactoryRoute._createChild` — o campo é inoperante

## What Changes

- BUG-6: adicionar `ArgumentError` antes do `route.builder!` em `_createShell`
- BUG-12: incluir `key:` ao construir `StatefulShellModuleRoute` em `withInjectedGuards`
- DESIGN-7: adicionar `runtimeType.hashCode` no `hashCode` de `ChildRoute`, `ModuleRoute`, `ShellModuleRoute`
- DESIGN-9: substituir `extra as T?` por `extra is T ? extra as T : null`
- BUG-ONEXIT: passar `onExit: route.onExit` em `GoRoute(...)` dentro de `_createChild`

## Capabilities

### New Capabilities
- Nenhuma

### Modified Capabilities

- `routing`: `_createShell` e `_createChild` no `FactoryRoute` — correções de runtime
- `extensions`: `getExtra<T>()` — contrato de retorno nulo corrigido

## Impact

**Arquivos modificados:**
- `lib/src/routes/factory_route.dart` — BUG-6, BUG-ONEXIT
- `lib/src/extensions/guard_extension.dart` — BUG-12
- `lib/src/routes/child_route.dart` — DESIGN-7
- `lib/src/routes/module_route.dart` — DESIGN-7
- `lib/src/routes/shell_module_route.dart` — DESIGN-7
- `lib/src/extensions/go_router_state_extension.dart` — DESIGN-9
