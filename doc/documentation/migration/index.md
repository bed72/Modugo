# 🔄 Guia de Migração

---

## Migrando de v2.x para v3.x

A versão 3.x trouxe mudanças significativas no sistema de injeção de dependências.

### Mudança principal: Sem dispose automático

Na v2.x, o Modugo descartava automaticamente as dependências dos módulos quando as rotas saíam da pilha de navegação. Na v3.x, **esse comportamento foi removido**.

#### Antes (v2.x)

```dart
// Dependências eram descartadas automaticamente ao sair do módulo
final class HomeModule extends Module {
  @override
  void binds() {
    // Registrado e descartado automaticamente
    i.registerSingleton<HomeController>(HomeController());
  }
}
```

#### Depois (v3.x+)

```dart
// Dependências vivem até o app encerrar
final class HomeModule extends Module {
  @override
  void binds() {
    // Registrado uma vez, vive para sempre
    i.registerSingleton<HomeController>(HomeController());
  }
}
```

### Por que essa mudança?

- **Consistência**: Evita inconsistências quando múltiplas rotas compartilham o mesmo módulo.
- **Simplicidade**: Elimina bugs relacionados a dispose prematuro de dependências.
- **Previsibilidade**: Dependências sempre disponíveis, sem surpresas.

### O que fazer

- Se você dependia do dispose automático, gerencie manualmente:

```dart
// Registrar
i.registerSingleton<MyService>(MyService());

// Quando não precisar mais (se necessário)
i.unregister<MyService>();
```

---

## Migrando de v3.x para v4.x

### Novidades

- API declarativa (DSL) com `route()`, `module()`, `alias()`, `shell()`, `statefulShell()`.
- `AliasRoute` para caminhos alternativos.
- Sistema de eventos nativo (`Event`).
- `IEvent` mixin para auto-cleanup de subscriptions.
- `AfterLayoutMixin` para callbacks pós-layout.
- `propagateGuards()` para propagação de guards em submódulos.
- Extensions expandidas (`GoRouterStateExtension`, `UriPathWithExtras`).
- Logger com cores ANSI e integração DevTools.

### Compatibilidade

A v4.x é **retrocompatível** com a v3.x. As APIs existentes continuam funcionando:

```dart
// Ainda funciona (v3 style)
ChildRoute(path: '/', child: (_, _) => const HomePage());
ModuleRoute(path: '/auth', module: AuthModule());

// Novo (v4 style) - opcional
route('/', child: (_, _) => const HomePage());
module('/auth', AuthModule());
```

Você pode migrar gradualmente, adotando a DSL rota por rota.
