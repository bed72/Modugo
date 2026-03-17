# Spec: Module System

**ID:** module-system
**Status:** stable
**Version:** 4.x

## Overview

O sistema de módulos é o núcleo do Modugo. Um `Module` é a unidade de encapsulamento
que agrega rotas, dependências e importações de outros módulos. Cada módulo é
registrado no máximo uma vez durante o ciclo de vida da aplicação.

---

## Capacidades

### CAP-MOD-01: Declaração de módulo

Um módulo DEVE estender `Module` com `final class`:

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [SharedModule()];

  @override
  void binds() {
    i.registerLazySingleton<HomeController>(() => HomeController());
  }

  @override
  List<IRoute> routes() => [
    child(child: (_, _) => const HomePage()),
  ];
}
```

**Regras:**
- `binds()` NÃO aceita parâmetros — usa o getter `i` (`GetIt.instance`)
- `imports()` retorna `List<IBinder>`, não `List<Module>`
- `routes()` retorna `List<IRoute>`

### CAP-MOD-02: Registro idempotente

Um módulo DEVE ser registrado no máximo uma vez, independente de quantos outros
módulos o importem.

**Comportamento:**
- O framework rastreia módulos registrados via `Set<Type> _modulesRegistered`
- Chamadas subsequentes para registrar o mesmo tipo são silenciosamente ignoradas
- Um warning é emitido via `Logger.module()` quando um módulo é ignorado
- Imports são processados **recursivamente antes** dos `binds()` do módulo atual

**Invariante:** Se A importa B que importa C, a ordem de registro é: C → B → A

### CAP-MOD-03: Ciclo de vida

O módulo expõe dois hooks de ciclo de vida:

| Método | Quando | Chamado automaticamente |
|---|---|---|
| `initState()` | Módulo inicializado | Sim (via `configureRoutes`) |
| `binds()` | Primeira vez que o módulo é registrado | Sim |
| `dispose()` | Módulo descartado | **Não** |

**Regra:** `dispose()` NÃO é chamado automaticamente. O consumidor é responsável
por invocar `dispose()` manualmente quando necessário.

```dart
final class ChatModule extends Module {
  @override
  void initState() {
    super.initState(); // DEVE chamar super
    // setup inicial: iniciar listeners, etc.
  }

  @override
  void dispose() {
    // limpar recursos: cancelar streams, etc.
    super.dispose(); // DEVE chamar super
  }
}
```

### CAP-MOD-04: Getter de injeção `i`

Todos os módulos herdam o getter `i` que é um atalho para `GetIt.instance`:

```dart
GetIt get i => GetIt.instance;
```

Este getter é o ponto de acesso para registro e resolução de dependências dentro
de `binds()`. Não deve ser substituído por subclasses.

### CAP-MOD-05: Acesso global à injeção

Fora de módulos, as dependências são acessadas via:

```dart
Modugo.i.get<T>()       // equivalente a GetIt.instance
GetIt.instance.get<T>()
context.read<T>()        // via BuildContext extension
```

### CAP-MOD-06: Composição de módulos

Módulos são compostos hierarquicamente no `AppModule` raiz:

```dart
final class AppModule extends Module {
  @override
  void binds() {
    i.registerSingleton<AuthService>(AuthService());
  }

  @override
  List<IRoute> routes() => [
    module(module: HomeModule()),
    module(module: AuthModule()),
    module(module: ProfileModule()),
  ];
}
```

---

## Restrições

- `Module` usa `with IBinder, IDsl, IRouter` (mixins), não `extends`
- Não há suporte a módulos escopados — todas as dependências são globais
- Dependências vivem por toda a vida do app a menos que removidas manualmente
- Imports circulares causam stack overflow — o framework não detecta ciclos

---

## Estrutura de arquivos recomendada

```
lib/
  modules/
    <feature>/
      <feature>_page.dart    # UI
      <feature>_module.dart  # Module subclass
  app_module.dart
  app_widget.dart
main.dart
```

---

## Casos de teste obrigatórios

- [ ] Módulo registra seus binds apenas uma vez mesmo com múltiplos imports
- [ ] Imports são processados na ordem correta (dependências antes do dependente)
- [ ] `initState()` é chamado na inicialização
- [ ] `dispose()` NÃO é chamado automaticamente
- [ ] `i` retorna `GetIt.instance`
- [ ] Módulo com `routes()` vazio não causa erro
