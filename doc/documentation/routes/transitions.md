# 🎨 Transições

O Modugo oferece 7 tipos de transição de página prontos para uso, integrados ao GoRouter via `CustomTransitionPage`.

---

## 🔹 Tipos Disponíveis

| Tipo | Descrição | Widget Interno |
|------|-----------|----------------|
| `TypeTransition.fade` | Cross-fade (padrão) | `FadeTransition` |
| `TypeTransition.scale` | Zoom in | `ScaleTransition` |
| `TypeTransition.slideUp` | Entra de baixo para cima | `SlideTransition` |
| `TypeTransition.slideDown` | Entra de cima para baixo | `SlideTransition` |
| `TypeTransition.slideLeft` | Entra da direita para esquerda | `SlideTransition` |
| `TypeTransition.slideRight` | Entra da esquerda para direita | `SlideTransition` |
| `TypeTransition.rotation` | Rotação | `RotationTransition` |

---

## 🔹 Aplicando em Rotas

### Por rota individual

```dart
route(
  '/details',
  child: (_, _) => const DetailsPage(),
  transition: TypeTransition.slideLeft,
);
```

Ou com a sintaxe tradicional:

```dart
ChildRoute(
  path: '/details',
  child: (_, _) => const DetailsPage(),
  transition: TypeTransition.slideLeft,
);
```

### Transição padrão global

Defina a transição padrão para todas as rotas via `Modugo.configure()`:

```dart
await Modugo.configure(
  module: AppModule(),
  pageTransition: TypeTransition.slideLeft,
);
```

> Se uma rota não define `transition`, a transição global é usada. O padrão global é `TypeTransition.fade`.

---

## 🔹 Usando `Transition.builder` Diretamente

Para cenários avançados, você pode usar o builder diretamente:

```dart
final transitionBuilder = Transition.builder(
  type: TypeTransition.slideUp,
  config: () => debugPrint('Aplicando transição'),
);
```

O `config` é um callback executado **antes** de construir a animação, útil para logging ou side-effects.
