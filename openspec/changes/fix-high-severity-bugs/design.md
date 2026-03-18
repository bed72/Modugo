## Context

Cinco bugs independentes em camadas diferentes da lib. Nenhum é interdependente,
todos podem ser corrigidos em sequência no mesmo PR.

## Goals / Non-Goals

**Goals:**
- Corrigir os 5 bugs sem breaking changes para usuários existentes
- Atualizar os testes de documentação de bugs para confirmar correção

**Non-Goals:**
- Refatorar arquitetura
- Mudar a API pública além dos contratos já documentados

## Decisions

### D1 — BUG-6: Guard antes de force-unwrap

```dart
// factory_route.dart — _createShell
builder: (context, state, child) {
  final b = route.builder;
  if (b == null) throw ArgumentError('ShellModuleRoute.builder must not be null');
  try {
    return b(context, state, child);
  } catch ...
}
```

### D2 — BUG-12: Preservar `key` em withInjectedGuards

```dart
// guard_extension.dart — StatefulShellModuleRouteExtensions
return StatefulShellModuleRoute(
  key: key,           // ← adicionar
  builder: builder,
  routes: injected,
  parentNavigatorKey: parentNavigatorKey,
);
```

### D3 — DESIGN-7: Incluir runtimeType no hashCode

```dart
// child_route.dart
int get hashCode =>
    path.hashCode ^
    name.hashCode ^
    transition.hashCode ^
    iosGestureEnabled.hashCode ^
    parentNavigatorKey.hashCode ^
    runtimeType.hashCode;  // ← adicionar
```

Mesmo padrão para `ModuleRoute` e `ShellModuleRoute`.

### D4 — DESIGN-9: Safe cast em getExtra

```dart
// go_router_state_extension.dart
T? getExtra<T>() => extra is T ? extra as T : null;
```

### D5 — BUG-ONEXIT: Passar onExit ao GoRoute

```dart
// factory_route.dart — _createChild
return GoRoute(
  path: route.path,
  name: route.name,
  onExit: route.onExit,   // ← adicionar
  parentNavigatorKey: route.parentNavigatorKey,
  redirect: ...,
  pageBuilder: ...,
);
```

## Risks / Trade-offs

**[DESIGN-9 safe cast]** → Código que dependia do `TypeError` para detectar tipo
errado passará a receber `null`. Isso é o comportamento correto documentado.

**[BUG-ONEXIT]** → `GoRoute.onExit` passa a ser chamado durante navegação para
trás. Código que define `onExit` mas não esperava que fosse invocado (porque estava
quebrado) pode ter comportamento alterado.

**[DESIGN-7 hashCode]** → `Set<ChildRoute>` e `Map<ChildRoute, V>` existentes podem
ter suas buckets invalidadas — mas esse é o comportamento correto.

## Migration Plan

Não há mudanças de API. Apenas fixes de contratos quebrados.
