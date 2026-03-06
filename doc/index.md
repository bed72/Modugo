![logo](assets/logo.png){ width="720" .center }

# Modugo — Modularize, injete e navegue 🚀

🎯 **Modugo** é um sistema modular para Flutter, inspirado no **Flutter Modular** e no **GoRouter Modular**. Ele oferece uma forma **limpa e organizada** de estruturar módulos, rotas e injeção de dependências, mantendo a simplicidade e clareza.

---

## 📦 Instalação

Adicione o Modugo ao seu `pubspec.yaml`:

```yaml
dependencies:
  modugo: ^4.2.6
```

Depois execute:

```bash
flutter pub get
```

---

## ▶️ Primeiros Passos

### 1. Crie seu módulo raiz

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>(AuthService());
  }

  @override
  List<IRoute> routes() => [
    route('/', child: (_, _) => const HomePage()),
    module('/profile', ProfileModule()),
  ];
}
```

### 2. Configure o Modugo no `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modugo.configure(module: AppModule(), initialRoute: '/');

  runApp(const AppWidget());
}
```

### 3. Use o router no `AppWidget`

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

## Por que Modugo? 🤔

O Modugo nasceu para resolver problemas comuns em apps grandes:

- 🧩 **Modularidade**: Divida sua aplicação em módulos isolados e reutilizáveis.
- 🔍 **Clareza**: Cada módulo define suas rotas e dependências de forma explícita.
- ⚡ **Injeção de dependências simples**: Baseado em **GetIt**, as dependências são registradas **uma vez** na inicialização.
- 🛣️ **Navegação robusta**: Com integração ao **GoRouter**, gerencie rotas de forma eficiente.
- 🔒 **Guards**: Proteja rotas com lógica condicional e propagação automática.
- 📡 **Eventos**: Comunicação desacoplada entre módulos via sistema de eventos nativo.
- 🎨 **Transições**: 7 tipos de animação de transição prontos para uso.

> 💡 **Nota importante:** Diferente de outros frameworks modulares, **Modugo não faz o dispose automático das dependências**. Todas as instâncias vivem até o encerramento do app.

---

## Base tecnológica 🛠️

| Área                   | Tecnologias usadas              |
| ---------------------- | ------------------------------- |
| Navegação              | GoRouter                        |
| Injeção de Dependência | GetIt                           |
| Modularização          | Módulos isolados e desacoplados |

---

## Funcionalidades ✅

- [x] Dependências registradas **uma vez** na inicialização.
- [x] Arquitetura **desacoplada** e modular.
- [x] Navegação simplificada com **GoRouter**.
- [x] API declarativa (DSL) para definição de rotas.
- [x] Guards com propagação automática para submódulos.
- [x] Sistema de eventos nativo para comunicação entre módulos.
- [x] 5 tipos de rotas: `ChildRoute`, `ModuleRoute`, `ShellModuleRoute`, `StatefulShellModuleRoute`, `AliasRoute`.
- [x] Extensions de contexto para navegação, matching e injeção.
- [x] `AfterLayoutMixin` para executar código pós-layout.
- [x] `CompilerRoute` para validação e extração de parâmetros de rotas.
- [x] Logging e diagnóstico integrado.

---

## Limitações ⚠️

- ❌ **Sem dispose automático**: Evita inconsistência quando múltiplas rotas compartilham o mesmo módulo.
- ✅ **Foco na estrutura e clareza**, não no gerenciamento automático de memória.

---
