# ▶️ Primeiros Passos

Este guia mostra como configurar o Modugo do zero em um projeto Flutter.

---

## 📦 Instalação

Adicione ao seu `pubspec.yaml`:

```yaml
dependencies:
  modugo: ^4.2.6
```

```bash
flutter pub get
```

---

## 🏗️ Configuração

### 1. Crie o módulo raiz

O módulo raiz (`AppModule`) é o ponto de entrada da sua aplicação. Ele agrega todos os submódulos, dependências globais e rotas.

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>(AuthService());
  }

  @override
  List<IRoute> routes() => [
    route('/', child: (_, _) => const HomePage()),
    module('/auth', AuthModule()),
    module('/profile', ProfileModule()),
  ];
}
```

### 2. Configure no `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(
    module: AppModule(),
    initialRoute: '/',
  );

  runApp(const AppWidget());
}
```

### 3. Crie o `AppWidget`

```dart
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: modugoRouter,
    );
  }
}
```

---

## ⚙️ Parâmetros de `Modugo.configure()`

| Parâmetro | Tipo | Default | Descrição |
|-----------|------|---------|-----------|
| `module` | `Module` | **obrigatório** | Módulo raiz da aplicação |
| `initialRoute` | `String` | `'/'` | Rota inicial |
| `pageTransition` | `TypeTransition` | `fade` | Transição padrão para todas as rotas |
| `debugLogDiagnostics` | `bool` | `false` | Habilita logs internos do Modugo |
| `debugLogDiagnosticsGoRouter` | `bool` | `false` | Habilita logs do GoRouter |
| `observers` | `List<NavigatorObserver>?` | `null` | Observers de navegação |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | `null` | Chave global do navigator |
| `redirect` | `FutureOr<String?> Function(...)` | `null` | Redirect global |
| `errorBuilder` | `Widget Function(...)` | `null` | Página de erro customizada |
| `onException` | `void Function(...)` | `null` | Callback de exceção |
| `refreshListenable` | `Listenable?` | `null` | Listenable para refresh do router |
| `redirectLimit` | `int` | `2` | Limite de redirects antes de erro |
| `extraCodec` | `Codec<Object?, Object?>?` | `null` | Codec para serialização de extras |

---

## 🔑 Acessando o Router

Existem duas formas de acessar o router configurado:

```dart
// Via getter global
modugoRouter

// Via classe Modugo
Modugo.routerConfig
```

Para navegação imperativa, use a chave global:

```dart
modugoNavigatorKey.currentState?.push(...);
```

---

## 🔑 Acessando Dependências

Três formas equivalentes:

```dart
// Via injector do módulo
final service = i.get<AuthService>();

// Via classe Modugo
final service = Modugo.i.get<AuthService>();

// Via BuildContext
final service = context.read<AuthService>();
```

---

## 📂 Estrutura Recomendada

```
/lib
  /modules
    /home
      home_page.dart
      home_module.dart
    /profile
      profile_page.dart
      profile_module.dart
    /auth
      auth_page.dart
      auth_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

Cada módulo encapsula suas próprias rotas, dependências e páginas, mantendo o código organizado e desacoplado.
