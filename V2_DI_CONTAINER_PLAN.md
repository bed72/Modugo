# Modugo V2 — Container DI com Lifecycle por Módulo

> Documento de referência para implementação do novo sistema de injeção de dependências do Modugo.
> Este plano substitui o uso do `GetIt` por um container próprio, leve, com scoping por módulo e dispose automático.

---

## Sumário

- [1. Motivação](#1-motivação)
- [2. Arquitetura atual (V1)](#2-arquitetura-atual-v1)
- [3. Visão geral da V2](#3-visão-geral-da-v2)
- [4. Fase 1 — Container próprio (Container)](#4-fase-1--container-próprio-modugocontainer)
- [5. Fase 2 — Integração com Module](#5-fase-2--integração-com-module)
- [6. Fase 3 — Dispose e lifecycle por módulo](#6-fase-3--dispose-e-lifecycle-por-módulo)
- [7. Fase 4 — Atualizar context.read](#7-fase-4--atualizar-contextread)
- [8. Fase 5 — Remover GetIt](#8-fase-5--remover-getit)
- [9. Fase 6 — Documentação e migration guide](#9-fase-6--documentação-e-migration-guide)
- [10. Ordem de execução](#10-ordem-de-execução)
- [11. Riscos e decisões em aberto](#11-riscos-e-decisões-em-aberto)

---

## 1. Motivação

O Modugo V1 usa `GetIt.instance` como container global de DI. Isso traz limitações concretas que impactam apps em produção:

### Problemas identificados

| Problema | Impacto |
|----------|---------|
| **Sem scoping por módulo** | Todas as dependências vivem no mesmo escopo global. Não há isolamento entre módulos. |
| **Sem dispose automático** | `Module.dispose()` existe mas é um método vazio que nunca é chamado pelo framework. Singletons ficam em memória pra sempre. |
| **`_modulesRegistered` nunca limpa** | O `Set<Type>` que previne duplicatas nunca remove entradas. Se um módulo for disposto, `binds()` não roda novamente ao re-navegar. |
| **Re-navegação quebrada** | Usuário navega para módulo A → sai → volta para A. Se A foi disposto, as dependências sumiram mas `_modulesRegistered` ainda contém A, então `binds()` não re-executa. |
| **GetIt não tem dispose por escopo** | `unregister()` é manual por tipo. `pushNewScope()`/`popScope()` é uma pilha linear que não funciona com navegação não-linear (tabs, shells, deep links). |

### Cenário real de bug

```
1. Usuário entra no módulo Profile → binds() registra ProfileController (singleton)
2. Usuário sai do módulo Profile
3. App tenta limpar → chama dispose() manualmente → ProfileController.dispose() roda
4. GetIt ainda tem ProfileController registrado (mas a instância foi disposed)
5. Usuário volta ao Profile → _modulesRegistered contém ProfileModule → binds() NÃO roda
6. context.read<ProfileController>() retorna a instância disposed → CRASH
```

---

## 2. Arquitetura atual (V1)

### Arquivos chave

| Arquivo | Responsabilidade |
|---------|-----------------|
| `lib/src/module.dart` | Classe base Module, `_configureBinders()`, `_modulesRegistered` |
| `lib/src/modugo.dart` | `Modugo.configure()`, `Modugo.i` (acesso ao GetIt) |
| `lib/src/mixins/binder_mixin.dart` | Interface IBinder: `binds()`, `imports()` |
| `lib/src/mixins/dsl_mixin.dart` | Mixin IDsl: helpers de rota (`child`, `module`, `alias`, `shell`, `statefulShell`) |
| `lib/src/mixins/router_mixin.dart` | Interface IRouter: `routes()` |
| `lib/src/extensions/context_injection_extension.dart` | `context.read<T>()`, `context.readAsync<T>()` |
| `lib/src/routes/factory_route.dart` | Converte IRoute → GoRoute, executa guards no redirect |

### Fluxo atual de DI

```
main()
  └─ Modugo.configure(module: RootModule())
       └─ module.configureRoutes()
            ├─ _configureBinders()          ← registra dependências
            │    ├─ imports() depth-first   ← módulos importados primeiro
            │    ├─ binds()                 ← usa i (GetIt.instance)
            │    └─ _modulesRegistered.add  ← previne re-registro
            └─ FactoryRoute.from(routes())  ← monta rotas do GoRouter
```

### Métodos GetIt usados atualmente

```dart
// Registro
i.registerSingleton<T>(instance)           // Singleton eager
i.registerLazySingleton<T>(() => T())      // Singleton lazy
i.registerFactory<T>(() => T())            // Factory (nova instância por chamada)
i.registerSingletonAsync<T>(asyncFactory)  // Singleton com init async

// Resolução
i.get<T>()                                 // Busca síncrona
i.getAsync<T>()                            // Busca assíncrona

// Reset
i.reset()                                  // Apenas em testes
```

---

## 3. Visão geral da V2

### Decisão

Criar um container DI leve e próprio do Modugo (`Container`) com:

- **Registro por tag** — cada módulo é automaticamente associado a uma tag (`runtimeType.toString()`)
- **`onDispose` callback por binding** — o desenvolvedor declara como limpar cada dependência no momento do registro
- **`disposeModule(tag)`** — limpa todos os binds de um módulo de uma vez, chamando os callbacks de dispose
- **Remoção de `_modulesRegistered` no dispose** — permite que `binds()` rode novamente quando o usuário voltar ao módulo

### Diagrama de conceito

```
Container
├─ _binds: Map<Type, Bind>           ← todos os bindings registrados
├─ _tagIndex: Map<String, Set<Type>> ← índice reverso tag → tipos
│
├─ Registro:
│   ├─ add<T>()             → factory (nova instância por chamada)
│   ├─ addSingleton<T>()    → singleton + onDispose callback
│   └─ addLazySingleton<T>() → lazy singleton + onDispose callback
│
├─ Resolução:
│   ├─ get<T>()     → resolve ou lança StateError
│   ├─ tryGet<T>()  → resolve ou retorna null
│   └─ isRegistered<T>() → bool
│
└─ Dispose:
    ├─ disposeModule(tag) → dispõe e remove todos os binds da tag
    └─ disposeAll()       → reset completo (testes)
```

---

## 4. Fase 1 — Container próprio (Container) `[CONCLUÍDA ✓]`

> **Resultado:** 41 testes novos em `test/container/modugo_container_test.dart`. Todos passando.
>
> **Arquivos criados:**
> - `lib/src/container/bind.dart` — modelo de binding com tipo, tag, onDispose e resolve
> - `lib/src/container/modugo_container.dart` — container completo com registro, resolução, dispose por tag, detecção de dependência circular, erro em registro duplicado, e dispose em ordem reversa
> - `test/container/modugo_container_test.dart` — 41 testes cobrindo todos os cenários planejados + extras

### 4.1 — Criar `lib/src/container/bind.dart`

Modelo que representa um binding registrado no container:

```dart
enum BindType { factory, singleton, lazySingleton }

final class Bind<T extends Object> {
  final T Function() create;
  final void Function(T instance)? onDispose;
  final BindType type;
  final String? tag;
  T? _instance;

  Bind({
    required this.create,
    required this.type,
    this.onDispose,
    this.tag,
  });

  /// Resolve a instância conforme o tipo de binding.
  ///
  /// - factory: sempre cria nova instância
  /// - singleton/lazySingleton: cria na primeira chamada, retorna cache depois
  T resolve(Container container) {
    return switch (type) {
      BindType.factory => create(container),
      BindType.singleton => _instance ??= create(container),
      BindType.lazySingleton => _instance ??= create(container),
    };
  }

  /// Chama onDispose se houver instância criada e callback definido.
  /// Limpa a referência interna após dispose.
  void dispose() {
    if (_instance != null && onDispose != null) {
      onDispose!(_instance as T);
    }
    _instance = null;
  }
}
```

**Sobre singleton vs lazySingleton:**

| Tipo | Quando cria | Quando dispõe |
|------|-------------|---------------|
| `factory` | Toda chamada `get<T>()` | Nunca (não mantém referência) |
| `singleton` | Primeiro `get<T>()` (pode ser eager no futuro) | `disposeModule(tag)` ou `disposeAll()` |
| `lazySingleton` | Primeiro `get<T>()` | `disposeModule(tag)` ou `disposeAll()` |

Hoje ambos são lazy na prática. A distinção existe para permitir evolução futura (eager init no `singleton`).

### 4.2 — Criar `lib/src/container/modugo_container.dart`

```dart
final class Container {
  /// Tag ativa durante execução de binds().
  /// Setada automaticamente pelo Module antes de chamar binds().
  /// Todos os registros feitos enquanto activeTag != null serão associados a essa tag.
  String? activeTag;

  /// Armazena todos os binds: Type → Bind
  final Map<Type, Bind> _binds = {};

  /// Índice reverso: tag → Set<Type>
  /// Permite dispor todos os binds de um módulo de uma vez.
  final Map<String, Set<Type>> _tagIndex = {};

  // ─── Registro ─────────────────────────────────────────────

  /// Registra uma factory. Nova instância criada a cada `get<T>()`.
  /// Factories não têm dispose (não mantêm referência).
  void add<T extends Object>(T Function() create) {
    _register<T>(create: create, type: BindType.factory);
  }

  /// Registra um singleton. Mesma instância retornada em todas as chamadas.
  /// [onDispose] é chamado quando o módulo for disposto.
  void addSingleton<T extends Object>(
    T Function() create, {
    void Function(T)? onDispose,
  }) {
    _register<T>(create: create, type: BindType.singleton, onDispose: onDispose);
  }

  /// Registra um lazy singleton. Instância criada no primeiro `get<T>()`.
  /// [onDispose] é chamado quando o módulo for disposto.
  void addLazySingleton<T extends Object>(
    T Function() create, {
    void Function(T)? onDispose,
  }) {
    _register<T>(create: create, type: BindType.lazySingleton, onDispose: onDispose);
  }

  void _register<T extends Object>({
    required T Function() create,
    required BindType type,
    void Function(T)? onDispose,
  }) {
    final tag = activeTag;

    _binds[T] = Bind<T>(
      create: create,
      type: type,
      onDispose: onDispose,
      tag: tag,
    );

    if (tag != null) {
      _tagIndex.putIfAbsent(tag, () => {}).add(T);
    }
  }

  // ─── Resolução ────────────────────────────────────────────

  /// Resolve uma instância do tipo [T].
  /// Lança [StateError] se não houver binding registrado.
  T get<T extends Object>() {
    final bind = _binds[T];
    if (bind == null) {
      throw StateError(
        'No binding found for type $T. '
        'Did you forget to register it in binds()?',
      );
    }
    return bind.resolve(this) as T;
  }

  /// Tenta resolver uma instância do tipo [T].
  /// Retorna null se não houver binding registrado (não lança exceção).
  T? tryGet<T extends Object>() {
    final bind = _binds[T];
    if (bind == null) return null;
    return bind.resolve(this) as T;
  }

  /// Verifica se existe um binding registrado para o tipo [T].
  bool isRegistered<T extends Object>() => _binds.containsKey(T);

  // ─── Dispose ──────────────────────────────────────────────

  /// Dispõe todos os binds associados a um módulo (tag).
  ///
  /// Para cada binding da tag:
  /// 1. Chama onDispose callback (se definido e instância existir)
  /// 2. Remove o binding do container
  ///
  /// Após esta chamada, `get<T>()` para tipos deste módulo lançará StateError.
  /// Se a tag não existir, não faz nada (safe to call).
  void disposeModule(String tag) {
    final types = _tagIndex.remove(tag);
    if (types == null) return;

    for (final type in types) {
      _binds[type]?.dispose();
      _binds.remove(type);
    }
  }

  /// Dispõe todos os binds do container.
  /// Chama onDispose de cada singleton e limpa tudo.
  /// Usado em testes ou reset completo da aplicação.
  void disposeAll() {
    for (final bind in _binds.values) {
      bind.dispose();
    }
    _binds.clear();
    _tagIndex.clear();
  }
}
```

### 4.3 — Testes do container

**Arquivo:** `test/container/modugo_container_test.dart`

#### Grupo: Registro e resolução

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 1 | factory retorna nova instância a cada get | `add<T>()` + dois `get<T>()` | `isNot(same(instance1))` |
| 2 | singleton retorna mesma instância | `addSingleton<T>()` + dois `get<T>()` | `same(instance1)` |
| 3 | lazySingleton retorna mesma instância | `addLazySingleton<T>()` + dois `get<T>()` | `same(instance1)` |
| 4 | lazySingleton só cria no primeiro get | Flag no factory, verificar antes e depois do get | Flag false antes, true depois |
| 5 | get de tipo não registrado lança StateError | `get<T>()` sem registro | `throwsA(isA<StateError>())` |
| 6 | tryGet retorna null se não existe | `tryGet<T>()` sem registro | `isNull` |
| 7 | tryGet retorna instância se existe | `tryGet<T>()` com registro | `isNotNull` |
| 8 | isRegistered retorna true/false | Antes e depois de registrar | `isFalse` / `isTrue` |

#### Grupo: Tagging (associação módulo ↔ binding)

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 9 | registro com activeTag associa ao módulo | Setar `activeTag = 'ModA'`, registrar | Binding pertence à tag |
| 10 | registro sem activeTag é global | Sem tag, registrar, `disposeModule('qualquer')` | Binding sobrevive |
| 11 | múltiplos bindings na mesma tag | Registrar 3 tipos com mesma tag | Todos associados |

#### Grupo: disposeModule

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 12 | disposeModule chama onDispose de cada singleton | Registrar com onDispose flag | Flag true após dispose |
| 13 | disposeModule remove binds do container | Após dispose, `get<T>()` | `throwsA(isA<StateError>())` |
| 14 | disposeModule não afeta outros módulos | Tag A e B, dispose A | B continua funcionando |
| 15 | disposeModule de tag inexistente não lança erro | `disposeModule('nope')` | Sem exceção |
| 16 | factory com onDispose: callback NÃO é chamado | Factory + onDispose + disposeModule | Callback não chamado (factory não guarda instância) |
| 17 | singleton sem onDispose: dispose não lança erro | Singleton sem callback + disposeModule | Sem exceção |

#### Grupo: disposeAll

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 18 | disposeAll limpa tudo | Registrar vários, disposeAll | Todos lançam erro |
| 19 | disposeAll chama onDispose de todos singletons | Múltiplos com callback | Todos chamados |

#### Grupo: Re-registro

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 20 | re-registro após dispose funciona | disposeModule → registrar novamente → get | Nova instância retornada |
| 21 | re-registro cria instância nova (não a antiga) | Singleton com estado → dispose → re-registro → get | Estado limpo |

#### Grupo: Dependências entre bindings

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 22 | singleton resolve dependência de outro binding | A depende de B, `get<A>()` | A recebe instância de B |
| 23 | factory resolve dependência de singleton | Factory depende de Singleton | Cada factory get recebe mesmo singleton |

---

## 5. Fase 2 — Integração com Module `[CONCLUÍDA ✓]`

> **Resultado:** 10 testes novos de integração + testes existentes migrados. 275 testes passando.
>
> **Arquivos modificados:**
> - `lib/src/module.dart` — GetIt → Container, `activeTag` antes de `binds()`, `dispose()` com `@mustCallSuper`, `modulesRegisteredForTest` exposto
> - `lib/src/modugo.dart` — `Modugo.container` (Container), `resetForTest()`, removido GetIt
> - `lib/src/extensions/context_injection_extension.dart` — `context.read<T>()` via container, adicionado `tryRead<T>()`, removido `readAsync`
> - `lib/src/mixins/binder_mixin.dart` — docs atualizados (sem refs a GetIt)
> - `lib/modugo.dart` — exporta container, removido export do GetIt
> - `pubspec.yaml` — removido `get_it` das dependencies
>
> **Testes modificados:**
> - `test/modugo_test.dart` — migrado de GetIt para Container
> - `test/extensions/context_injection_extension_test.dart` — migrado, removido readAsync, adicionado tryRead
>
> **Testes criados:**
> - `test/container/module_container_integration_test.dart` — 10 testes cobrindo todos os cenários planejados

### 5.1 — Mudanças em `lib/src/module.dart`

```dart
abstract class Module with IBinder, IDsl, IRouter {
  /// Container de DI do Modugo (substitui GetIt).
  Container get i => Modugo.container;

  /// Tag do módulo — usada para scoping de binds.
  /// Por padrão usa o nome do tipo. Pode ser sobrescrito se necessário.
  String get tag => runtimeType.toString();

  /// Chamado quando o módulo é inicializado.
  void initState() {}

  /// Chamado quando o módulo é disposto.
  /// Limpa todos os binds associados a este módulo e permite re-registro.
  @mustCallSuper
  void dispose() {
    Modugo.container.disposeModule(tag);
    _modulesRegistered.remove(runtimeType); // ← CRÍTICO: permite re-registro
  }

  List<RouteBase> configureRoutes() {
    _configureBinders();
    return FactoryRoute.from(routes());
  }

  void _configureBinders({IBinder? binder}) {
    final target = binder ?? this;
    if (_modulesRegistered.contains(target.runtimeType)) return;

    // Imports primeiro (depth-first)
    for (final imported in target.imports()) {
      _configureBinders(binder: imported);
    }

    // Setar tag ativa ANTES de chamar binds()
    // Todos os registros feitos dentro de binds() serão associados a esta tag
    Modugo.container.activeTag =
        (target is Module) ? target.tag : target.runtimeType.toString();
    target.binds();
    Modugo.container.activeTag = null;

    _modulesRegistered.add(target.runtimeType);
    Logger.module('${target.runtimeType} binds registered');
  }
}
```

### 5.2 — Nova API de binds() (comparação V1 vs V2)

```dart
// ━━━ ANTES (V1 — GetIt) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ProfileModule extends Module {
  @override
  void binds() {
    i.registerLazySingleton<ProfileRepo>(() => ProfileRepoImpl());
    i.registerFactory<ProfileController>(
      () => ProfileController(i.get<ProfileRepo>()),
    );
  }
}

// ━━━ DEPOIS (V2 — Container) ━━━━━━━━━━━━━━━━━━━━━━━━━

class ProfileModule extends Module {
  @override
  void binds() {
    i.addLazySingleton<ProfileRepo>(
      () => ProfileRepoImpl(),
      onDispose: (repo) => repo.close(), // ← dispose declarado no registro
    );
    i.add<ProfileController>(
      () => ProfileController(i.get<ProfileRepo>()),
    );
  }
}
```

**Diferenças chave:**
- O parâmetro `c` (container) é passado ao factory, permitindo resolver dependências explicitamente
- `onDispose` é declarado junto com o registro — não precisa lembrar de limpar no `dispose()`
- Factory (`add`) não precisa de `onDispose` (não mantém referência)

### 5.3 — Testes de integração Module + Container

**Arquivo:** `test/container/module_container_integration_test.dart`

| # | Teste | Descrição | Asserção |
|---|-------|-----------|----------|
| 1 | binds() registra no container com tag correta | Verificar que bindings pertencem à tag do módulo | Tag presente no container |
| 2 | imports() resolve antes do módulo atual | A importa B → verificar ordem de execução | B.binds() antes de A.binds() |
| 3 | imports recursivos funcionam | A importa B, B importa C | Ordem: C → B → A |
| 4 | módulo duplicado em imports não roda binds() duas vezes | A e B importam C | C.binds() executa 1x |
| 5 | dispose() limpa binds do módulo | Após dispose, get do módulo falha | `throwsA(isA<StateError>())` |
| 6 | dispose() remove de _modulesRegistered | Após dispose, tipo não está no set | `isFalse` |
| 7 | **re-registro após dispose** | dispose() → configureRoutes() → get | Funciona, nova instância |
| 8 | dispose de módulo A não afeta módulo B | A e B registrados, dispose A | B.get continua ok |
| 9 | dispose de módulo não dispõe imports | A importa Shared, dispose A | Shared continua disponível |
| 10 | onDispose callbacks chamados no dispose | Registrar com callback flag | Flag true após dispose |

---

## 6. Fase 3 — Dispose e lifecycle por módulo `[CONCLUÍDA ✓]`

> **Resultado:** 8 testes novos de lifecycle. 283 testes passando.
>
> **Arquivo criado:**
> - `test/container/module_lifecycle_test.dart` — 8 testes cobrindo cenários reais de navegação
>
> **Cenários cobertos:**
> 1. Navegar → dispose → voltar → instância nova (goBack)
> 2. Singleton mantém estado sem dispose
> 3. Dispose limpa estado + chama onDispose callbacks
> 4. Imports sobrevivem ao dispose do importador
> 5. Dispose duplo não lança erro
> 6. onDispose chamado exatamente 1x
> 7. onDispose NÃO chamado se lazy singleton nunca acessado
> 8. Múltiplos módulos com lifecycles independentes (dispose + re-registro)
>
> **Decisão final:** Dispose manual por padrão + `disposeOnExit: true` opt-in no `ModuleRoute`.
>
> **Arquivos adicionais criados:**
> - `lib/src/routes/module_route.dart` — adicionado campo `disposeOnExit` (default `false`)
> - `lib/src/widgets/module_dispose_scope.dart` — `StatefulWidget` que chama `module.dispose()` no `State.dispose()`
> - `lib/src/routes/factory_route.dart` — `_createModule` envolve com `ModuleDisposeScope` quando `disposeOnExit: true`
> - `test/container/dispose_on_exit_test.dart` — 5 testes (default false, set true, auto-dispose on unmount, re-registro após dispose, widget vivo não dispõe)

### 6.1 — O problema do dispose automático

O GoRouter **não tem hook nativo** de "módulo saiu da árvore de navegação". Precisamos decidir como/quando chamar `dispose()`.

#### Opção A — Manual (pragmática)

O Modugo garante que `dispose()` funciona corretamente. O desenvolvedor decide quando chamar.

```dart
// Exemplo: chamar dispose manualmente ao sair de uma feature
context.go('/home');
profileModule.dispose(); // limpa tudo do ProfileModule
```

#### Opção B — Via `onExit` do ChildRoute

O `ChildRoute` já suporta `onExit`. Podemos usar para disparar dispose ao sair da rota principal de um módulo.

```dart
// O Modugo poderia injetar isso automaticamente no ModuleRoute
onExit: (context, state) {
  module.dispose();
  return true;
}
```

#### Opção C — Via NavigatorObserver

Criar um observer que mapeia rotas a módulos e chama dispose quando a rota sai da stack.

```dart
class ModugoNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    // Detectar se a rota pertence a um módulo e chamar dispose
  }
}
```

#### Decisão

**Começar com Opção A (manual).** O importante agora é que `dispose()` funcione corretamente — a automação pode ser adicionada depois sem breaking changes.

### 6.2 — Testes de lifecycle completo

**Arquivo:** `test/container/module_lifecycle_test.dart`

Estes testes simulam cenários reais de navegação:

| # | Cenário | Passos simulados | Resultado esperado |
|---|---------|------------------|--------------------|
| 1 | **Navegar → dispose → voltar** | configureRoutes A → get<T> ok → dispose A → configureRoutes A → get<T> | Funciona, nova instância criada |
| 2 | **Singleton mantém estado sem dispose** | configureRoutes A → get<T> → setar estado → (simular navegar para B e voltar) → get<T> | Mesma instância, estado mantido |
| 3 | **Dispose limpa estado** | configureRoutes A → get<T> → setar estado → dispose A → configureRoutes A → get<T> | Nova instância, estado limpo |
| 4 | **Import sobrevive ao dispose do importador** | A importa Shared → dispose A → get<Shared> | Shared continua disponível |
| 5 | **Dispose duplo não lança erro** | dispose A → dispose A | Sem exceção |
| 6 | **onDispose chamado exatamente 1x** | Singleton com counter no onDispose → dispose | Counter == 1 |
| 7 | **onDispose NÃO chamado se singleton nunca foi acessado** | Registrar lazy singleton → dispose sem get | onDispose NÃO chamado (_instance é null) |
| 8 | **Múltiplos módulos com ciclos independentes** | A e B registrados → dispose A → re-registrar A → B intacto | Ambos funcionam |

---

## 7. Fase 4 — Atualizar context.read `[CONCLUÍDA ✓]`

> **Resultado:** `context.read<T>()` simplificado, `tryRead<T>()` adicionado, `readAsync` removido.
>
> **Arquivos modificados:**
> - `lib/src/extensions/context_injection_extension.dart` — migrado de GetIt para `Modugo.container`
> - `test/extensions/context_injection_extension_test.dart` — migrado, removido readAsync, adicionado tryRead

### 7.1 — Nova implementação de `lib/src/extensions/context_injection_extension.dart`

```dart
extension ContextInjectionExtension on BuildContext {
  /// Resolve uma instância do tipo [T] do container de DI.
  /// Lança [StateError] se não houver binding registrado.
  T read<T extends Object>() => Modugo.container.get<T>();

  /// Tenta resolver uma instância do tipo [T] do container de DI.
  /// Retorna null se não houver binding registrado.
  T? tryRead<T extends Object>() => Modugo.container.tryGet<T>();
}
```

**Mudanças:**
- Removido `readAsync<T>()` — o container V2 é síncrono
- Removidos parâmetros `param1`, `param2`, `instanceName`, `type` (simplificação)
- Adicionado `tryRead<T>()` — versão safe que retorna null

**Sobre `readAsync` removido:** se o app precisa de inicialização assíncrona, deve fazê-la antes de `Modugo.configure()` no `main()` ou no `initState()` do módulo.

### 7.2 — Testes

**Arquivo:** `test/extensions/context_injection_extension_test.dart` (atualizar existente)

| # | Teste | Asserção |
|---|-------|----------|
| 1 | `context.read<T>()` resolve do container | Instância retornada |
| 2 | `context.read<T>()` de tipo não registrado lança erro | `throwsA(isA<StateError>())` |
| 3 | `context.tryRead<T>()` retorna null se não existe | `isNull` |
| 4 | `context.tryRead<T>()` retorna instância se existe | `isNotNull` |

---

## 8. Fase 5 — Remover GetIt `[CONCLUÍDA ✓]`

> **Resultado:** GetIt completamente removido do projeto. 288 testes passando.
>
> **Arquivos modificados:**
> - `pubspec.yaml` — removido `get_it` das dependencies
> - `lib/modugo.dart` — removido export do GetIt, adicionado exports do container
> - `lib/src/modugo.dart` — `Modugo.container` (Container), `resetForTest()`
> - `lib/src/module.dart` — `Container get i`, tag, dispose com `@mustCallSuper`
> - `lib/src/mixins/binder_mixin.dart` — docs atualizados
> - Todos os testes migrados de `GetIt.instance.reset()` para `Modugo.resetForTest()`

### 8.1 — Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `pubspec.yaml` | Remover `get_it` das dependencies |
| `lib/src/module.dart` | Remover `import 'package:get_it/get_it.dart'` → trocar `GetIt get i` por `Container get i` |
| `lib/src/modugo.dart` | Remover import GetIt → adicionar `static final Container _container = Container()` → expor `static Container get container => _container` |
| `lib/src/extensions/context_injection_extension.dart` | Remover import GetIt → usar `Modugo.container` |
| `lib/modugo.dart` (barrel) | Adicionar exports: `container/bind.dart`, `container/modugo_container.dart` |
| Todos os testes com `GetIt.instance.reset()` | Trocar por `Modugo.container.disposeAll()` |

### 8.2 — Checklist de busca e substituição

Buscar estas strings em **todo o projeto** e garantir que foram removidas/substituídas:

| Buscar | Substituir por |
|--------|---------------|
| `import 'package:get_it/get_it.dart'` | `import 'package:modugo/src/container/modugo_container.dart'` |
| `GetIt.instance` | `Modugo.container` |
| `GetIt.I` | `Modugo.container` |
| `GetIt get i` | `Container get i` |
| `static GetIt get i` | `static Container get container` |
| `i.registerSingleton<T>(x)` | `i.addSingleton<T>(() => x)` |
| `i.registerLazySingleton<T>(() => x)` | `i.addLazySingleton<T>(() => x)` |
| `i.registerFactory<T>(() => x)` | `i.add<T>(() => x)` |
| `i.registerSingletonAsync` | Removido (ver nota sobre async) |
| `i.getAsync<T>()` | Removido |
| `GetIt.instance.reset()` | `Modugo.container.disposeAll()` |
| `get_it` (em pubspec.yaml) | Remover linha |

### 8.3 — Rodar todos os testes

```bash
flutter test
```

Todos os 224+ testes existentes devem continuar passando após a migração.

---

## 9. Fase 6 — Documentação e migration guide `[CONCLUÍDA ✓]`

> **Resultado:** Toda documentação atualizada para V2 API.
>
> **Arquivos atualizados:**
> - `doc/documentation/injection/index.md` — reescrito para Container
> - `doc/documentation/modules/index.md` — reescrito com dispose, lifecycle, disposeOnExit
> - `doc/documentation/extensions/index.md` — `read<T>()`, `tryRead<T>()`, removido readAsync
> - `doc/index.md` — removidas referências a GetIt, atualizado para V2
> - `README.md` — removidas referências a GetIt, documentado nova API, disposeOnExit, tryRead

### 9.1 — Tabela de migração (breaking changes)

| V1 (GetIt) | V2 (Container) | Notas |
|---|---|---|
| `i.registerSingleton<T>(T())` | `i.addSingleton<T>(() => T(), onDispose: (t) => t.close())` | onDispose é opcional |
| `i.registerLazySingleton<T>(() => T())` | `i.addLazySingleton<T>(() => T(), onDispose: (t) => t.close())` | onDispose é opcional |
| `i.registerFactory<T>(() => T())` | `i.add<T>(() => T())` | Sem onDispose (factory não guarda ref) |
| `i.get<T>()` | `i.get<T>()` | **Sem mudança** |
| `context.read<T>()` | `context.read<T>()` | **Sem mudança** |
| `context.readAsync<T>()` | Removido | Inicializar antes de `configure()` |
| `Modugo.i` | `Modugo.container` | Tipo muda de GetIt para Container |
| `Module.dispose()` (vazio) | `Module.dispose()` (limpa binds + permite re-registro) | **Funcional agora** |
| `i.registerSingletonAsync<T>(fn)` | Removido | Usar `await` antes de `configure()` |
| `context.read<T>(param1: x)` | Removido | Parâmetros não suportados |
| `context.read<T>(instanceName: 'x')` | Removido | Named instances não suportados |

### 9.2 — Documentação a atualizar

| Arquivo | Conteúdo a atualizar |
|---------|---------------------|
| `doc/documentation/modules/index.md` | Exemplos de binds() com nova API |
| `doc/documentation/dependency-injection/index.md` | Toda a seção de DI |
| `README.md` | Exemplos de uso |
| `CHANGELOG.md` | Entry para V2 com breaking changes |

---

## 10. Ordem de execução

```
Fase 1 ─── Container (Bind + Container) + 23 testes
  │
  ├── Fase 2 ─── Integrar no Module + 10 testes
  │     │
  │     └── Fase 3 ─── Dispose lifecycle + 8 testes
  │
  └── Fase 4 ─── context.read/tryRead + 4 testes
        │
        └── Fase 5 ─── Remover GetIt + migrar testes existentes
              │
              └── Fase 6 ─── Documentação + migration guide
```

| Fase | Escopo | Depende de | Testes novos |
|------|--------|------------|--------------|
| **1** | `Bind` + `Container` | Nenhuma | 23 |
| **2** | Integrar no `Module` + `_configureBinders` | Fase 1 | 10 |
| **3** | Dispose lifecycle + cenários de goBack | Fase 2 | 8 |
| **4** | `context.read<T>()` + `context.tryRead<T>()` | Fase 1 | 4 |
| **5** | Remover GetIt de todo o projeto | Fases 1-4 | 0 (migrar existentes) |
| **6** | Docs + migration guide | Fase 5 | 0 |
| | | **Total de testes novos:** | **45** |

---

## 11. Riscos e decisões em aberto

### 11.1 — Dependência circular

~~O container V2 **não detecta** dependências circulares.~~

**Decisão: Detectar desde a Fase 1.** Usar `Set<Type> _resolving` durante `get<T>()`. Se o tipo já estiver no set, lançar `StateError` descritivo. Cobrir com testes.

### 11.2 — Singleton eager vs lazy

Na V1, `registerSingleton` cria a instância **imediatamente**. No V2, `addSingleton` cria no primeiro `get()` (igual lazy).

**Opções:**
- (a) Manter ambos lazy — simplifica o container
- (b) `addSingleton` cria imediatamente após `binds()` — requer um `commit()` ou eager init no final de `_configureBinders`

**Recomendação:** Opção (a) por agora. Eager init pode ser adicionado depois se necessário.

### 11.3 — Async binds

V1 tem `registerSingletonAsync`. V2 não terá.

**Impacto:** Apps que usam `i.registerSingletonAsync` precisarão mover a inicialização async para antes de `Modugo.configure()`:

```dart
// ANTES (V1)
void binds() {
  i.registerSingletonAsync<Database>(() async => await Database.init());
}

// DEPOIS (V2)
Future<void> main() async {
  final db = await Database.init();  // ← async resolvido antes
  await Modugo.configure(module: AppModule(db: db));
  runApp(MyApp());
}
```

### 11.4 — Named instances

GetIt suporta `instanceName` para registrar múltiplas instâncias do mesmo tipo. V2 não terá.

**Impacto:** Quem usa named instances precisará criar wrapper types:

```dart
// ANTES (V1)
i.registerSingleton<Database>(primaryDb, instanceName: 'primary');
i.registerSingleton<Database>(cacheDb, instanceName: 'cache');

// DEPOIS (V2) — criar tipos distintos
i.addSingleton<PrimaryDatabase>(() => PrimaryDatabase());
i.addSingleton<CacheDatabase>(() => CacheDatabase());
```

### 11.5 — Sobrescrita de binding (mesmo tipo registrado duas vezes)

**Decisão: Lançar erro.** Se `binds()` tentar registrar um tipo que já existe no container, lançar `StateError` com mensagem descritiva informando qual tipo e qual tag tentou sobrescrever. Isso previne bugs silenciosos e força o dev a organizar as dependências corretamente.

### 11.6 — Ordem de dispose

**Decisão: Dispose em ordem reversa de registro.** Quando `disposeModule(tag)` é chamado, os bindings são dispostos na ordem inversa em que foram registrados. Isso garante que dependências "folha" (registradas por último) sejam limpas antes das dependências que elas consomem. Exemplo: Controller (registrado depois) é disposto antes do Repository (registrado antes), evitando que Controller.onDispose tente acessar um Repository já disposto.

### 11.7 — Dispose automático vs manual

Fase 3 começa com dispose manual. A automação (via NavigatorObserver ou onExit) é uma evolução futura que **não requer breaking changes** — basta adicionar a chamada automática a `dispose()`.
