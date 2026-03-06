# 📡 Sistema de Eventos

O Modugo inclui um sistema de eventos leve e type-safe para comunicação desacoplada entre módulos. Ele usa a API nativa de `Stream` do Dart, sem dependências externas.

---

## 🔹 Conceito

O sistema de eventos permite que módulos se comuniquem **sem se conhecerem diretamente**. Um módulo emite um evento e qualquer outro módulo pode ouvir e reagir.

---

## 🔹 Definindo um Evento

Crie uma classe simples para representar o evento:

```dart
final class UserLoggedInEvent {
  final String userId;
  UserLoggedInEvent(this.userId);
}

final class CartUpdatedEvent {
  final int itemCount;
  CartUpdatedEvent(this.itemCount);
}
```

---

## 🔹 Emitindo Eventos

Use `Event.emit<T>()` para disparar um evento:

```dart
Event.emit(UserLoggedInEvent('user-123'));
Event.emit(CartUpdatedEvent(5));
```

---

## 🔹 Ouvindo Eventos

### Via `Event.on<T>()`

```dart
Event.i.on<UserLoggedInEvent>((event) {
  print('Usuário logou: ${event.userId}');
});
```

### Via `Event.i.streamOf<T>()`

Para acesso ao stream diretamente:

```dart
Event.i.streamOf<CartUpdatedEvent>().listen((event) {
  print('Carrinho atualizado: ${event.itemCount} itens');
});
```

---

## 🔹 Limpeza de Listeners

### Remover listener de um tipo específico

```dart
Event.i.dispose<UserLoggedInEvent>();
```

### Remover todos os listeners

```dart
Event.i.disposeAll();
```

---

## 🔹 IEvent Mixin — Eventos em Módulos

O mixin `IEvent` integra o sistema de eventos ao ciclo de vida do módulo, com **auto-cleanup** das subscriptions:

```dart
final class ChatModule extends Module with IEvent {
  @override
  void listen() {
    on<UserLoggedInEvent>((event) {
      print('Chat: usuário ${event.userId} conectou');
    });

    on<CartUpdatedEvent>((event) {
      print('Chat: carrinho com ${event.itemCount} itens');
    });
  }

  @override
  List<IRoute> routes() => [
    route('/', child: (_, _) => const ChatPage()),
  ];
}
```

### Comportamento

- `listen()` é chamado automaticamente quando o módulo é inicializado (via `initState()`).
- Todas as subscriptions registradas via `on<T>()` são canceladas automaticamente no `dispose()`.
- O parâmetro `autoDispose` controla se a subscription é rastreada:

```dart
on<MyEvent>((e) => ..., autoDispose: true);  // cancelada no dispose (padrão)
on<MyEvent>((e) => ..., autoDispose: false); // vive independente do módulo
```

---

## 🔹 RouteChangedEventModel

O Modugo emite automaticamente um `RouteChangedEventModel` sempre que a rota muda:

```dart
Event.i.on<RouteChangedEventModel>((event) {
  print('Navegou para: ${event.location}');
});
```

Isso é útil para analytics, logging ou qualquer lógica que dependa de mudanças de rota.

---

## 🔹 Exemplo Completo

```dart
// Definição do evento
final class ProductViewedEvent {
  final String productId;
  ProductViewedEvent(this.productId);
}

// Emissão (em qualquer lugar)
Event.emit(ProductViewedEvent('prod-42'));

// Escuta no módulo de analytics
final class AnalyticsModule extends Module with IEvent {
  @override
  void listen() {
    on<ProductViewedEvent>((event) {
      Analytics.trackProductView(event.productId);
    });

    on<RouteChangedEventModel>((event) {
      Analytics.trackPageView(event.location);
    });
  }

  @override
  List<IRoute> routes() => [];
}
```
