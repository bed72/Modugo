## MODIFIED Requirements

### Requirement: Bootstrap — Modugo.configure() parameters
`Modugo.configure()` SHALL accept `enableIOSGestureNavigation: bool` (default `true`)
in addition to all existing parameters.

| Parâmetro | Tipo | Default | Descrição |
|---|---|---|---|
| `module` | `Module` | **obrigatório** | Módulo raiz |
| `initialRoute` | `String` | `'/'` | Rota inicial |
| `pageTransition` | `TypeTransition` | `fade` | Transição padrão |
| `enableIOSGestureNavigation` | `bool` | `true` | Habilita CupertinoPage no iOS para back swipe |
| `debugLogDiagnostics` | `bool` | `false` | Logs internos do Modugo |
| `debugLogDiagnosticsGoRouter` | `bool` | `false` | Logs do GoRouter |
| `observers` | `List<NavigatorObserver>?` | `null` | Observers de navegação |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | `null` | Chave global do navigator |
| `redirect` | `FutureOr<String?> Function(...)?` | `null` | Redirect global |
| `errorBuilder` | `Widget Function(...)?` | `null` | Página de erro customizada |
| `onException` | `void Function(...)?` | `null` | Callback de exceção |
| `refreshListenable` | `Listenable?` | `null` | Listenable para refresh do router |
| `redirectLimit` | `int` | `2` | Limite de redirects antes de erro |
| `extraCodec` | `Codec<Object?, Object?>?` | `null` | Codec para serializar extras |

#### Scenario: enableIOSGestureNavigation defaults to true
- **WHEN** `Modugo.configure(module: AppModule())` is called without `enableIOSGestureNavigation`
- **THEN** `Modugo.enableIOSGestureNavigation` SHALL be `true`

#### Scenario: enableIOSGestureNavigation can be disabled globally
- **WHEN** `Modugo.configure(enableIOSGestureNavigation: false)` is called
- **THEN** `Modugo.enableIOSGestureNavigation` SHALL be `false`

---

## ADDED Requirements

### Requirement: TypeTransition enum includes native value
The `TypeTransition` enum SHALL include `native` as the 8th value.

#### Scenario: TypeTransition has 8 values
- **WHEN** `TypeTransition.values` is accessed
- **THEN** it SHALL contain exactly 8 values including `native`

---

### Requirement: CAP-RTE-10 — iOS back-swipe gesture navigation
All routes created by `FactoryRoute._transition()` SHALL support the iOS back-swipe
gesture when `enableIOSGestureNavigation` is `true` and no explicit custom transition
is set. The full precedence order is:

```
TypeTransition.native         → CupertinoPage (iOS) / MaterialPage (outros)
iosGestureEnabled: false      → CustomTransitionPage (override explícito)
iosGestureEnabled: true       → CupertinoPage se iOS
global enableIOSGestureNavigation: true + plataforma iOS → CupertinoPage
caso contrário                → CustomTransitionPage
```

#### Scenario: precedence — native wins over all
- **WHEN** `transition: TypeTransition.native` AND `iosGestureEnabled: false`
- **THEN** SHALL return `CupertinoPage` on iOS (native is highest precedence)

#### Scenario: precedence — per-route false over global true
- **WHEN** global `true` AND per-route `iosGestureEnabled: false`
- **THEN** SHALL return `CustomTransitionPage` on iOS

#### Scenario: precedence — explicit custom transition over global true
- **WHEN** global `true` AND `transition: TypeTransition.fade`
- **THEN** SHALL return `CustomTransitionPage` with fade animation on iOS
