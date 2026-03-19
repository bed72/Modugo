# Spec: Event System

**ID:** events
**Status:** stable
**Version:** 4.x

## Overview

Sistema de eventos type-safe e leve para comunicação desacoplada entre módulos.
Baseado em `Stream` nativo do Dart, sem dependências externas. Um singleton
`Event` centraliza o broadcast. O mixin `IEvent` integra o sistema ao ciclo de
vida dos módulos com auto-cleanup de subscriptions.

---

## Capacidades

### CAP-EVT-01: Definição de eventos

Eventos são classes simples (sem herança obrigatória):

```dart
final class UserLoggedInEvent {
  final String userId;
  const UserLoggedInEvent(this.userId);
}

final class CartUpdatedEvent {
  final int itemCount;
  const CartUpdatedEvent(this.itemCount);
}
```

### CAP-EVT-02: Emissão

```dart
Event.emit(UserLoggedInEvent('user-123'));
Event.emit(CartUpdatedEvent(5));
```

`emit` é estático e faz broadcast para **todos** os listeners do tipo `T`.

### CAP-EVT-03: Escuta

```dart
// Subscribe com callback
Event.i.on<UserLoggedInEvent>((event) {
  print('Usuário logou: ${event.userId}');
});

// Acesso direto ao Stream<T>
Event.i.streamOf<CartUpdatedEvent>().listen((event) {
  print('Carrinho: ${event.itemCount} itens');
});
```

`Event.i` é a instância singleton do event bus.

### CAP-EVT-04: Limpeza de listeners

```dart
// Remove todos os listeners de um tipo específico
Event.i.dispose<UserLoggedInEvent>();

// Remove todos os listeners de todos os tipos
Event.i.disposeAll();
```

### CAP-EVT-05: IEvent mixin — integração com módulos

O mixin `IEvent` integra o event bus ao módulo com ativação automática e cleanup manual:

```dart
final class AnalyticsModule extends Module with IEvent {
  @override
  void listen() {
    // subscriptions aqui são canceladas ao chamar dispose() no módulo
    on<UserLoggedInEvent>((event) {
      Analytics.trackLogin(event.userId);
    });

    on<RouteChangedEventModel>((event) {
      Analytics.trackPageView(event.location);
    });

    // autoDispose: false → vive além do módulo
    on<SystemEvent>((e) => handleSystem(e), autoDispose: false);
  }

  @override
  List<IRoute> routes() => [];
}
```

**Comportamento do IEvent:**
- `listen()` é chamado automaticamente por `_configureBinders()` após os `binds()` do módulo serem registrados
- `listen()` NÃO depende de `Module.initState()` (que foi removido)
- `on<T>()` com `autoDispose: true` (padrão) → subscription cancelada no `dispose()`
- `on<T>()` com `autoDispose: false` → subscription persiste após o dispose do módulo
- `dispose()` é método próprio do `IEvent` mixin (não override de `Module`)
- `dispose()` NÃO é chamado automaticamente — é responsabilidade do consumidor

### CAP-EVT-06: RouteChangedEventModel

Evento emitido **automaticamente** pelo framework a cada mudança de rota:

```dart
Event.i.on<RouteChangedEventModel>((event) {
  print('Navegou para: ${event.location}');
});
```

Útil para analytics, logging ou qualquer lógica que dependa da rota atual.
Não requer nenhuma configuração adicional.

### CAP-EVT-07: Padrão de uso entre módulos

```dart
// Módulo A emite
Event.emit(ProductViewedEvent('prod-42'));

// Módulo B escuta (sem conhecer o Módulo A)
final class TrackingModule extends Module with IEvent {
  @override
  void listen() {
    on<ProductViewedEvent>((event) {
      Tracker.track('product_view', {'id': event.productId});
    });
  }
}
```

### CAP-EVT-08: Ordem de cleanup — IEvent antes de unregister

Quando um módulo com `IEvent` precisa de cleanup completo, a ordem correta é:

1. `module.dispose()` — cancela event subscriptions (IEvent)
2. `i.unregister<T>()` ou `i.reset()` — remove binds (GetIt chama dispose callbacks)

Se a ordem for invertida, event listeners ativos podem tentar acessar serviços
já removidos do GetIt, causando erros em runtime.

```dart
// CORRETO
analyticsModule.dispose(); // cancela listeners primeiro
i.unregister<AnalyticsService>(); // depois remove o serviço

// ERRADO — pode causar erro se listener usa AnalyticsService
i.unregister<AnalyticsService>();
analyticsModule.dispose();
```

### CAP-EVT-09: Padrão de reset global

Para reset completo (ex: logout), cancelar todos os event listeners antes
de resetar o GetIt:

```dart
void logout() async {
  // 1. Cancelar todos os event listeners globais
  Event.i.disposeAll();

  // 2. Resetar GetIt (chama dispose callbacks)
  Module.resetRegistrations();
  await Modugo.i.reset();
}
```

---

## Restrições

- O event bus é **global** — não há escopo por módulo
- `Event.emit` funciona mesmo sem nenhum listener ativo (fire-and-forget)
- Listeners são executados **síncronamente** na thread do emissor
- `StreamController` usado internamente é `broadcast` — permite múltiplos listeners
- `on<T>()` do mixin `IEvent` só deve ser chamado dentro de `listen()`
- Ao fazer cleanup, cancelar event listeners ANTES de remover dependências do GetIt

---

## Casos de teste obrigatórios

- [ ] `Event.emit` entrega o evento a todos os listeners do tipo
- [ ] `Event.emit` sem listeners não lança erro
- [ ] `Event.i.on` recebe eventos emitidos após a subscription
- [ ] `Event.i.dispose<T>()` cancela listeners do tipo T
- [ ] `Event.i.disposeAll()` cancela todos os listeners
- [ ] `IEvent.on` com `autoDispose: true` é cancelado no `dispose()` do módulo
- [ ] `IEvent.on` com `autoDispose: false` persiste após `dispose()` do módulo
- [ ] `RouteChangedEventModel` é emitido a cada navegação
- [ ] `Event.i.streamOf<T>()` retorna stream com os eventos do tipo T
- [ ] Cleanup na ordem correta: `IEvent.dispose()` antes de `unregister()`
- [ ] Reset global: `Event.i.disposeAll()` antes de `i.reset()`
