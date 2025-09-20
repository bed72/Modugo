# 🏗 Arquitetura Modular em Flutter

Em uma arquitetura modular, seu app é dividido em **módulos independentes**, cada um responsável por um recurso ou domínio específico. Essa abordagem melhora a **escalabilidade, testabilidade e manutenibilidade**.

---

## 🔹 Estrutura de Projeto Exemplo

```
/lib
  /modules
    /home
      home_page.dart
      home_module.dart
    /profile
      profile_page.dart
      profile_module.dart
    /chat
      chat_page.dart
      chat_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

- `/modules`: contém todos os módulos de recursos do app.
- Cada pasta de módulo (ex.: `home`, `profile`, `chat`) contém:

  - `*_page.dart`: a interface principal do módulo
  - `*_module.dart`: responsável pelo **roteamento** e **injeção de dependências** do módulo

- `app_module.dart`: módulo raiz que agrega todos os módulos de recursos e dependências globais
- `app_widget.dart`: widget principal que inicializa o app com rotas e configuração de módulos
- `main.dart`: ponto de entrada do app

---

## ⚡ Como os Módulos Funcionam

1. **Encapsulamento**: Cada módulo gerencia suas próprias rotas, dependências e interface.
2. **Roteamento**: Os módulos definem suas próprias rotas, que são posteriormente compostas pelo módulo raiz.
3. **Injeção de Dependência**: Cada módulo pode registrar suas próprias dependências localmente ou globalmente.
4. **Escalabilidade**: Novos recursos podem ser adicionados como novos módulos sem afetar os existentes.

---

## 📝 Exemplo: Módulo App

```dart
// app_module.dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>((_) => AuthService());
  }

  @override
  List<IRoute> routes() => [
    ModuleRoute(path: '/', module: HomeModule()),
    ModuleRoute(path: '/chat', module: ChatModule()),
    ModuleRoute(path: '/profile', module: ProfileModule()),
  ];
}
```

- `binds()`: registra dependências específicas do módulo.
- `routes()`: declara as rotas do módulo, encapsulando a interface dentro do seu domínio.

---

## 🚀 Benefícios

- **Separação de Responsabilidades**: UI, rotas e dependências são modularizadas.
- **Facilidade de Testes**: Cada módulo pode ser testado de forma independente.
- **Reutilização**: Módulos podem ser reutilizados em diferentes apps.
- **Colaboração em Equipe**: Times podem trabalhar em módulos diferentes simultaneamente sem conflitos.
