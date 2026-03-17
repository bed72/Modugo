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

O mixin `IEvent` integra o event bus ao ciclo de vida do módulo:

```dart
final class AnalyticsModule extends Module with IEvent {
  @override
  void listen() {
    // subscriptions aqui são auto-canceladas no dispose() do módulo
    on<UserLoggedInEvent>((event) {
      Analytics.trackLogin(event.userId);
    });

    on<RouteChangedEventModel>((event) {
      Analytics.trackPageView(event.location);
    });

    // autoDispose: false → vive além do módulo
    on<SystemEvent>((e) => ..., autoDispose: false);
  }

  @override
  List<IRoute> routes() => [];
}
```

**Comportamento do IEvent:**
- `listen()` é chamado automaticamente em `initState()`
- `on<T>()` com `autoDispose: true` (padrão) → subscription cancelada no `dispose()`
- `on<T>()` com `autoDispose: false` → subscription persiste após o dispose do módulo

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

---

## Restrições

- O event bus é **global** — não há escopo por módulo
- `Event.emit` funciona mesmo sem nenhum listener ativo (fire-and-forget)
- Listeners são executados **síncronamente** na thread do emissor
- `StreamController` usado internamente é `broadcast` — permite múltiplos listeners
- `on<T>()` do mixin `IEvent` só deve ser chamado dentro de `listen()`

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
