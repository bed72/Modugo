---
name: modugo
description: >
  Contexto completo do projeto Modugo — lib Flutter de roteamento modular e
  injeção de dependência sobre GoRouter + GetIt. Carregue esta skill sempre que
  for explorar, implementar, especificar ou revisar qualquer coisa no repositório.
license: MIT
metadata:
  author: modugo-team
  version: "2.0"
---

# Modugo — Skill de Arquitetura

## O que é o Modugo

Pacote Flutter (`pub.dev: modugo`, v4.x) de **roteamento modular** e **injeção de dependência** sobre:

- **GoRouter** (`^17.x`) — roteamento declarativo baseado em URL
- **GetIt** (`^9.x`) — service locator / DI

Filosofia: cada `Module` encapsula suas próprias rotas, dependências e importações.
Dependências **não são auto-dispostas** — vivem por toda a vida do app a menos que
sejam removidas manualmente.

---

## Mapa de Arquitetura

```
lib/
├── modugo.dart                        ← barrel export público
└── src/
    ├── modugo.dart                    ← Modugo.configure() + modugoRouter + modugoNavigatorKey
    ├── module.dart                    ← Module base class
    ├── guard.dart                     ← propagateGuards()
    ├── logger.dart                    ← Logger (ANSI + dart:developer)
    ├── transition.dart                ← TypeTransition enum + Transition.builder
    ├── routes/
    │   ├── child_route.dart           ← ChildRoute
    │   ├── module_route.dart          ← ModuleRoute
    │   ├── alias_route.dart           ← AliasRoute
    │   ├── shell_module_route.dart    ← ShellModuleRoute
    │   ├── stateful_shell_module_route.dart
    │   ├── compiler_route.dart        ← CompilerRoute (validação/extração de path params)
    │   └── factory_route.dart         ← IRoute → GoRouter RouteBase converter
    ├── interfaces/
    │   ├── guard_interface.dart       ← IGuard
    │   └── route_interface.dart       ← IRoute marker
    ├── mixins/
    │   ├── binder_mixin.dart          ← IBinder (binds + imports)
    │   ├── router_mixin.dart          ← IRouter (routes)
    │   ├── dsl_mixin.dart             ← IDsl (child/module/alias/shell/statefulShell)
    │   ├── event_mixin.dart           ← IEvent
    │   └── after_layout_mixin.dart    ← AfterLayoutMixin
    ├── events/
    │   └── event.dart                 ← Event singleton (stream bus)
    ├── models/
    │   └── route_change_event_model.dart
    ├── extensions/
    │   ├── context_injection_extension.dart
    │   ├── context_navigation_extension.dart
    │   ├── context_match_extension.dart
    │   ├── go_router_state_extension.dart
    │   ├── uri_extension.dart
    │   └── guard_extension.dart
    └── decorators/
        └── guard_module_decorator.dart
```

---

## Module System

### Assinatura correta

```dart
// lib/src/module.dart
abstract class Module with IBinder, IDsl, IRouter {
  // Shortcut para GetIt.instance — NÃO é parâmetro, é getter
  GetIt get i => GetIt.instance;

  // NÃO possui initState() nem dispose() — lifecycle mínimo
  // Mixins como IEvent adicionam seus próprios métodos de ciclo de vida

  List<RouteBase> configureRoutes();   // chamado internamente pelo framework
}

// lib/src/mixins/binder_mixin.dart
mixin IBinder {
  void binds() {}                        // sem parâmetro — usa getter 'i'
  List<IBinder> imports() => const [];   // retorna List<IBinder>, não List<Module>
}
```

> **Erro comum**: `void binds(Injector i)` está ERRADO. A assinatura é `void binds()`.
> O acesso ao GetIt é feito via `i.registerX<T>(...)` onde `i` é o getter herdado.

### Comportamento de registro

- Módulos são registrados **no máximo uma vez** — `Set<Type> _modulesRegistered`
- `imports()` são processados **recursivamente antes** dos `binds()` do módulo atual
- Ordem: `C → B → A` se A importa B que importa C

### Ciclo de vida

| Método | Quando | Chamado automaticamente? |
|---|---|---|
| `binds()` | Primeira vez que o módulo é registrado | Sim |
| `IEvent.listen()` | Após binds (se módulo usa `IEvent`) | Sim (via `_configureBinders`) |
| `IEvent.dispose()` | Cleanup de subscriptions | **NÃO** — gerenciar manualmente |

O `Module` base **NÃO possui** `initState()` nem `dispose()`. Mixins como `IEvent`
adicionam métodos de ciclo de vida específicos à sua responsabilidade.

```dart
final class AnalyticsModule extends Module with IEvent {
  @override
  void listen() {
    // chamado automaticamente após binds() durante _configureBinders()
    on<UserLoggedInEvent>((event) {
      Analytics.trackLogin(event.userId);
    });
  }
}
```

### Exemplo completo

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [SharedModule()];  // List<IBinder>, não List<Module>

  @override
  void binds() {
    // 'i' é o getter GetIt.instance — sem parâmetro
    i
      ..registerSingleton<ServiceRepository>(ServiceRepository.instance)
      ..registerLazySingleton<HomeController>(() => HomeController(i.get<ApiClient>()));
  }

  @override
  List<IRoute> routes() => [
    child(child: (_, _) => const HomePage()),   // método DSL: child(), não route()
  ];
}
```

---

## Bootstrap

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modugo.configure(module: AppModule(), initialRoute: '/');
  runApp(const AppWidget());
}

// app_widget.dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: modugoRouter);
}
```

### Modugo.configure() — Parâmetros Completos

| Parâmetro | Tipo | Default | Descrição |
|---|---|---|---|
| `module` | `Module` | **obrigatório** | Módulo raiz |
| `initialRoute` | `String` | `'/'` | Rota inicial |
| `pageTransition` | `TypeTransition` | `fade` | Transição padrão |
| `debugLogDiagnostics` | `bool` | `false` | Logs internos do Modugo |
| `debugLogDiagnosticsGoRouter` | `bool` | `false` | Logs do GoRouter |
| `observers` | `List<NavigatorObserver>?` | `null` | Observers de navegação |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | `null` | Chave global do navigator |
| `redirect` | `FutureOr<String?> Function(...)?` | `null` | Redirect global |
| `errorBuilder` | `Widget Function(...)?` | `null` | Página de erro customizada |
| `onException` | `void Function(...)?` | `null` | Callback de exceção |
| `refreshListenable` | `Listenable?` | `null` | Listenable para refresh do router |
| `redirectLimit` | `int` | `2` | Limite de redirects antes de erro |
| `extraCodec` | `Codec<Object?, Object?>?` | `null` | Codec para serializar extras |

### Globais expostos

```dart
modugoRouter          // RouterConfig — usar em MaterialApp.router
Modugo.routerConfig   // alias para modugoRouter
Modugo.i              // GetIt.instance
modugoNavigatorKey    // GlobalKey<NavigatorState> — para navegação imperativa
```

---

## Injeção de Dependências (GetIt)

### Tipos de registro

```dart
// Singleton — instância única já criada
i.registerSingleton<T>(instance, {String? instanceName, bool signalsReady = false});

// Lazy Singleton — criado na primeira chamada a get<T>()
i.registerLazySingleton<T>(FactoryFunc<T> func, {String? instanceName});

// Factory — nova instância a cada get<T>()
i.registerFactory<T>(FactoryFunc<T> func, {String? instanceName});

// Singleton Assíncrono — criado via Future
i.registerSingletonAsync<T>(FactoryFuncAsync<T> func, {
  String? instanceName,
  List<Type>? dependsOn,    // aguarda esses tipos antes de criar
  bool signalsReady = false,
});

// Singleton com dependências declaradas
i.registerSingletonWithDependencies<T>(FactoryFunc<T> func, {
  List<Type>? dependsOn,
  bool signalsReady = false,
});

// Factory Assíncrona
i.registerFactoryAsync<T>(FactoryFuncAsync<T> func, {String? instanceName});
```

### Acessando dependências

```dart
// Via getter 'i' dentro de Module
i.get<T>()
i.get<T>(instanceName: 'primary')

// Via GetIt diretamente (equivalente)
Modugo.i.get<T>()
GetIt.instance.get<T>()

// Via BuildContext (extension)
context.read<T>()
context.read<T>(instanceName: 'primary')
context.read<T>(param1: value, param2: value)   // factories parametrizadas
await context.readAsync<T>()                      // async singleton
```

### Exemplo com dependências assíncronas

```dart
void binds() {
  i.registerSingletonAsync<ConfigService>(() async {
    final cfg = ConfigService();
    await cfg.init();
    return cfg;
  });

  i.registerSingletonAsync<ApiClient>(
    () async => ApiClient(i.get<ConfigService>()),
    dependsOn: [ConfigService],   // aguarda ConfigService estar pronto
  );
}
```

### Dispose e cleanup de dependências

O GetIt oferece mecanismos de dispose que NÃO são chamados automaticamente.
O desenvolvedor DEVE invocar explicitamente `unregister()`, `reset()` ou `popScope()`.

```dart
// 1. dispose: callback no registro
i.registerSingleton<DbService>(
  DbService(),
  dispose: (service) => service.close(),  // chamado em unregister/reset/popScope
);

// 2. Interface Disposable — GetIt detecta automaticamente no reset/popScope
class CacheService implements Disposable {
  @override
  FutureOr onDispose() => clearCache();
}

// 3. Scopes — agrupar registros com ciclo de vida limitado
i.pushNewScope(scopeName: 'checkout');
i.registerSingleton<PaymentService>(PaymentService());
await i.popScope();  // remove tudo do scope e chama dispose callbacks

// 4. Remoção individual
i.unregister<T>();
i.resetLazySingleton<T>();  // dispõe e permite recriar na próxima chamada
```

| Método | O que faz |
|---|---|
| `unregister<T>()` | Remove e dispõe a instância |
| `reset()` | Dispõe e remove tudo (ordem reversa) |
| `resetLazySingleton<T>()` | Dispõe e permite recriar na próxima chamada |
| `popScope()` | Dispõe tudo registrado no scope atual |
| `dropScope('name')` | Dispõe e remove scope nomeado |

### Ordem de cleanup com IEvent

Quando um módulo usa `IEvent` e seus binds têm dispose callbacks, a ordem é:

```dart
// 1. Cancelar event subscriptions PRIMEIRO
module.dispose();

// 2. DEPOIS remover binds
i.unregister<AnalyticsService>();

// Para reset global (ex: logout):
Event.i.disposeAll();         // cancelar todos os event listeners
Module.resetRegistrations();  // limpar módulos registrados
await Modugo.i.reset();      // resetar GetIt (chama dispose callbacks)
```

---

## Rotas — Tipos e DSL

### Tipos de rota

| Classe | Uso |
|---|---|
| `ChildRoute` | Página folha — path + widget builder |
| `ModuleRoute` | Delega para sub-`Module` |
| `AliasRoute` | Caminho alternativo para um `ChildRoute` existente |
| `ShellModuleRoute` | Layout persistente (GoRouter `ShellRoute`) |
| `StatefulShellModuleRoute` | Multi-stack com estado por branch (GoRouter `StatefulShellRoute`) |

`FactoryRoute.from()` converte `List<IRoute>` → `List<RouteBase>` do GoRouter.

### DSL — Métodos do mixin IDsl

> **ATENÇÃO**: o método para criar `ChildRoute` é `child()`, **não** `route()`.
> As docstrings internas do repositório usam `route()` em alguns exemplos por inconsistência histórica,
> mas o método real é `child()`.

```dart
// ChildRoute
ChildRoute child({
  required Widget Function(BuildContext, GoRouterState) child,
  String? name,
  String? path,                      // default: '/'
  TypeTransition? transition,
  List<IGuard> guards = const [],
  GlobalKey<NavigatorState>? parentNavigatorKey,
  Page<dynamic> Function(BuildContext, GoRouterState)? pageBuilder,
  FutureOr<bool> Function(BuildContext, GoRouterState)? onExit,
})

// ModuleRoute
ModuleRoute module({
  required Module module,
  String? name,
  GlobalKey<NavigatorState>? parentNavigatorKey,
  // path fixado em '/' — o path é definido em routes() do módulo pai
})

// AliasRoute
AliasRoute alias({required String from, required String to})

// ShellModuleRoute
ShellModuleRoute shell({
  required List<IRoute> routes,
  required Widget Function(BuildContext, GoRouterState, Widget) builder,
  List<NavigatorObserver>? observers,
  GlobalKey<NavigatorState>? navigatorKey,
  GlobalKey<NavigatorState>? parentNavigatorKey,
  Page<dynamic> Function(BuildContext, GoRouterState, Widget)? pageBuilder,
})

// StatefulShellModuleRoute
StatefulShellModuleRoute statefulShell({
  required List<IRoute> routes,
  required Widget Function(BuildContext, GoRouterState, StatefulNavigationShell) builder,
  GlobalKey<StatefulNavigationShellState>? key,
  GlobalKey<NavigatorState>? parentNavigatorKey,
})
```

### Exemplo completo de routes()

```dart
@override
List<IRoute> routes() => [
  child(child: (_, _) => const HomePage()),

  child(
    path: '/details/:id',
    name: 'details',
    child: (_, state) => DetailsPage(id: state.getPathParam('id')!),
    guards: [AuthGuard()],
    transition: TypeTransition.slideLeft,
  ),

  module(module: AuthModule()),

  alias(from: '/cart/:id', to: '/order/:id'),

  shell(
    builder: (_, _, child) => AppScaffold(child: child),
    routes: [
      child(path: '/dashboard', child: (_, _) => const DashboardPage()),
      child(path: '/settings', child: (_, _) => const SettingsPage()),
    ],
  ),

  statefulShell(
    builder: (_, _, shell) => BottomBarWidget(shell: shell),
    routes: [
      module(module: FeedModule()),
      module(module: ProfileModule()),
    ],
  ),
];
```

### AliasRoute — limitações

- Funciona **apenas para** `ChildRoute` (não para `ModuleRoute` ou `ShellModuleRoute`)
- Deve apontar para `ChildRoute` existente **no mesmo módulo**
- Não há alias encadeados

### Transições

| Tipo | Descrição |
|---|---|
| `TypeTransition.fade` | Cross-fade (padrão global) |
| `TypeTransition.scale` | Zoom in |
| `TypeTransition.slideUp` | De baixo para cima |
| `TypeTransition.slideDown` | De cima para baixo |
| `TypeTransition.slideLeft` | Da direita para esquerda |
| `TypeTransition.slideRight` | Da esquerda para direita |
| `TypeTransition.rotation` | Rotação |

---

## Guards

```dart
// Interface
abstract class IGuard {
  FutureOr<String?> call(BuildContext context, GoRouterState state);
  // null  → permite acesso
  // String → redireciona para esse path
}
```

### Aplicando guards

```dart
// Por rota
child(
  path: '/dashboard',
  child: (_, _) => const DashboardPage(),
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
)

// Em todo o módulo via propagateGuards
List<IRoute> routes() => propagateGuards(
  guards: [AuthGuard(repository: i.get<AuthRepository>())],
  routes: [
    module(module: HomeModule()),
    module(module: ProfileModule()),
  ],
);
```

### Ordem de execução

```
1. Guards propagados do pai → executados primeiro (prepend)
2. Guards da rota atual
3. Se todos retornarem null → navegação prossegue
4. Se algum retornar String → redirect
5. redirect da rota (se definido) → avaliado após guards
```

### Tipos comuns

```dart
// Auth
final class AuthGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) async =>
      await checkAuth() ? null : '/login';
}

// Role
final class AdminGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    final user = context.read<UserService>().currentUser;
    return user.isAdmin ? null : '/unauthorized';
  }
}

// Side-effect sem redirect (ex: analytics)
final class AnalyticsGuard implements IGuard {
  @override
  FutureOr<String?> call(BuildContext context, GoRouterState state) {
    Analytics.logPageView(state.uri.path);
    return null;
  }
}
```

---

## Sistema de Eventos

```dart
// Emitir
Event.emit<T>(event);              // broadcast para todos os listeners de T

// Ouvir
Event.i.on<T>(callback);           // subscribe — retorna StreamSubscription
Event.i.streamOf<T>();             // acesso direto ao Stream<T>

// Limpar
Event.i.dispose<T>();              // remove listeners de T específico
Event.i.disposeAll();              // remove todos os listeners
```

### RouteChangedEventModel

Emitido **automaticamente** a cada navegação:

```dart
Event.i.on<RouteChangedEventModel>((event) {
  print('Navegou para: ${event.location}');
});
```

### IEvent mixin — event listening em módulos

```dart
final class ChatModule extends Module with IEvent {
  @override
  void listen() {
    // subscriptions registradas aqui são canceladas no dispose()
    on<UserLoggedInEvent>((event) { /* ... */ });

    // autoDispose: false → subscription vive além do módulo
    on<SystemEvent>((e) => handleSystem(e), autoDispose: false);
  }
}
```

- `listen()` é chamado automaticamente por `_configureBinders()` após `binds()`
- `on<T>()` com `autoDispose: true` (padrão) → cancelado no `dispose()`
- `dispose()` é método próprio do `IEvent` mixin — **NÃO** é chamado automaticamente

---

## Extensions

### ContextNavigationExtension

```dart
context.go('/path', extra: data)
context.goNamed('name', pathParameters: {'id': '1'}, queryParameters: {'tab': 'x'})
context.push('/path')
context.pushNamed('name', ...)
context.pop([result])
context.canPop()                     // bool
context.canPush('/path')             // bool — verifica se rota existe
context.replace('/path')
context.pushReplacement('/path')
context.replaceNamed('name', ...)
context.pushReplacementNamed('name', ...)
context.reload()                     // recarrega rota atual
await context.replaceStack(['/home', '/profile'])   // substitui toda a pilha
context.goRouter                     // acessa GoRouter instance
```

### ContextMatchExtension

```dart
context.isKnownPath('/settings')         // bool
context.isKnownRouteName('profile')      // bool
context.matchingRoute('/user/42')        // GoRoute?
context.matchParams('/user/42')          // Map<String, String>?
context.state                            // GoRouterState atual
```

### ContextInjectionExtension

```dart
context.read<T>()
context.read<T>(instanceName: 'primary')
context.read<T>(param1: v1, param2: v2)   // factory parametrizada
await context.readAsync<T>()
```

### GoRouterStateExtension

```dart
state.getPathParam('id')              // String?
state.getStringQueryParam('q')        // String?
state.getIntQueryParam('page')        // int?
state.getBoolQueryParam('active')     // bool?
state.getExtra<T>()                   // T? — cast do extra
state.argumentsOrThrow<T>()           // T — throws se null/tipo errado
state.effectivePath                   // String — path do extra['path'] ou uri.path
state.isInitialRoute                  // bool — matchedLocation == '/'
state.isCurrentRoute('name')          // bool
state.locationSegments                // List<String> — '/a/b' → ['a', 'b']
```

### UriExtension

```dart
uri.fullPath                          // path + query + fragment
uri.hasQueryParam('key')              // bool
uri.getQueryParam('key', defaultValue: 'x')  // String?
uri.isSubPathOf(other)                // bool
uri.withAppendedPath('sub')           // Uri
```

---

## Utilitários

### CompilerRoute

Validação, compilação e manipulação de padrões de rota dinâmicos (usa `path_to_regexp`).

```dart
final route = CompilerRoute('/user/:id');

route.match('/user/42')        // true
route.match('/product/42')     // false
route.extract('/user/42')      // {'id': '42'}
route.build({'id': '42'})      // '/user/42'
route.parameters               // ['id']
route.regExp                   // RegExp compilado

// Múltiplos parâmetros
CompilerRoute('/user/:userId/post/:postId')
  .extract('/user/1/post/99')  // {'userId': '1', 'postId': '99'}

// extract ignora query params e fragments automaticamente
route.extract('/user/42?tab=info#top')  // {'id': '42'}

// Inválidos — lançam FormatException
CompilerRoute('/user/:(id')   // sintaxe inválida
CompilerRoute('/user/ :id')   // espaço no path
```

### Logger

Habilitado via `Modugo.configure(debugLogDiagnostics: true)`.

| Método | Nível | Cor ANSI |
|---|---|---|
| `Logger.information(msg)` | INFO | Azul |
| `Logger.debug(msg)` | DEBUG | Verde |
| `Logger.warn(msg)` | WARN | Amarelo |
| `Logger.error(msg)` | ERROR | Vermelho |
| `Logger.module(msg)` | MODULE | Ciano |
| `Logger.injection(msg)` | INJECT | Verde |
| `Logger.dispose(msg)` | DISPOSE | Cinza |
| `Logger.navigation(msg)` | NAVIGATION | Ciano |

Formato de saída: `[HH:mm:ss][LEVEL] mensagem` — via `stdout.writeln` + `developer.log`.

### AfterLayoutMixin

Executa callback após o **primeiro frame** renderizado.

```dart
class MyScreen extends StatefulWidget { /* ... */ }

class _MyScreenState extends State<MyScreen> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) => const Scaffold(/* ... */);

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    // contexto válido — seguro para navegar, exibir dialogs, etc.
    context.read<HomeController>().loadData();
  }
}
```

- Chamado **uma única vez** após o primeiro frame
- Verifica `mounted` antes de executar
- Suporta `FutureOr<void>`

---

## Convenções de Código

| Regra | Detalhe |
|---|---|
| Aspas simples | `prefer_single_quotes: true` (obrigatório) |
| `avoid_print` | `false` — Logger interno é aceitável |
| Dart SDK | `>=3.10.0 <4.0.0` |
| Flutter | `>=3.38.1` |
| Testes | `mocktail ^1.0.4` — **nunca** `mockito` |
| Arquivos | `snake_case` |
| Classes | `PascalCase` |
| Mixins | prefixo `I` — `IBinder`, `IRouter`, `IDsl` |
| Interfaces | em `interfaces/`, implementações em `src/` |
| Módulos `final class` | prefer `final class AppModule extends Module` |

### Padrão de arquivo de teste

```dart
void main() {
  group('NomeDoComponente', () {
    late Dependency dependency;

    setUp(() {
      dependency = MockDependency();
    });

    test('deve fazer X quando Y', () {
      // arrange
      // act
      // assert
    });
  });
}
```

### Estrutura de projeto recomendada

```
lib/
  modules/
    home/
      home_page.dart
      home_module.dart
    profile/
      profile_page.dart
      profile_module.dart
    auth/
      auth_page.dart
      auth_module.dart
  app_module.dart
  app_widget.dart
main.dart
```

---

## Spec-Driven Development com OpenSpec

Este repositório usa **OpenSpec** (`openspec/`). Workflow:

```
proposal.md → specs/ → design.md → tasks.md → implementação
```

| Comando | Uso |
|---|---|
| `/opsx:propose` | Proposta + artefatos completos |
| `/opsx:apply` | Implementa tasks de uma mudança |
| `/opsx:explore` | Exploração livre de ideias |
| `/opsx:archive` | Arquiva mudança concluída |

Specs de capacidades vivem em `openspec/specs/<capacidade>/spec.md`.

**Regras SDD:**
1. Spec antes de código — nova funcionalidade começa com `openspec/specs/<feature>/spec.md`
2. Proposta antes de implementar — use `/opsx:propose`
3. Tasks atômicas — uma task = um commit
4. Specs são fonte de verdade — atualize ao mudar comportamento

---

## MCPs Disponíveis

### Context7 — IDs corretos

```
go_router  → /websites/pub_dev_go_router      (1274 snippets, reputação High)
get_it     → /fluttercommunity/get_it          (142 snippets, reputação High)
flutter    → resolver com libraryName: "flutter"
```

**Quando usar:**
- Verificar API atual de `ShellRoute`, `StatefulShellRoute`, `GoRouterState`
- Confirmar assinaturas de `registerLazySingleton`, `registerSingletonAsync`
- Exemplos de navegação avançada com GoRouter

### GitHub octocode

```
owner: "bed72", repo: "Modugo"
```

**Quando usar:**
- Entender decisões de design via histórico de PRs
- Verificar padrões existentes antes de introduzir novos
- Comparar com `flutter_modular`, `go_router_modular`

---

## Invariantes Críticas

1. `Modugo.configure()` é **idempotente** — retorna router cacheado em chamadas repetidas
2. `binds()` não tem parâmetro — `i` é getter (`GetIt get i => GetIt.instance`)
3. `imports()` retorna `List<IBinder>`, não `List<Module>`
4. DSL usa `child()` para `ChildRoute` — **não** `route()`
5. Módulos registrados no máximo uma vez — `Set<Type> _modulesRegistered`
6. `Module` NÃO possui `initState()` nem `dispose()` — lifecycle mínimo
7. `IEvent.dispose()` **não é chamado automaticamente** — gerenciar manualmente
8. Guards: `null` = permite, `String` = redireciona
9. `AliasRoute` funciona apenas para `ChildRoute` no mesmo módulo
10. `StatefulShellModuleRoute` preserva estado de cada branch independentemente
11. Toda navegação emite `RouteChangedEventModel` automaticamente

---

## Testes

```bash
flutter test                                          # todos
flutter test --coverage                               # com cobertura
flutter test test/routes/                             # apenas rotas
flutter analyze                                       # análise estática
dart format --set-exit-if-changed lib test            # check de formatação
```

CI: format → analyze → test → coverage → deploy docs (`.github/workflows/ci.yml`)
