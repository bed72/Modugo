# Spec: Utilities

**ID:** utilities
**Status:** stable
**Version:** 4.x

## Overview

Utilitários auxiliares do Modugo: `CompilerRoute` para validação e manipulação
de path patterns, `Logger` para logging interno e `AfterLayoutMixin` para
callbacks pós-primeiro-frame.

---

## Capacidades

### CAP-UTL-01: CompilerRoute

Valida, compila e manipula padrões de rota dinâmicos usando `path_to_regexp`.

```dart
final route = CompilerRoute('/user/:id');
```

**API completa:**

| Método/Getter | Retorno | Descrição |
|---|---|---|
| `match(path)` | `bool` | Verifica se o path corresponde ao padrão |
| `extract(path)` | `Map<String, String>?` | Extrai parâmetros do path |
| `build(args)` | `String` | Constrói path concreto a partir de parâmetros |
| `parameters` | `List<String>` | Nomes dos parâmetros do padrão |
| `regExp` | `RegExp` | Expressão regular compilada |

```dart
// Correspondência
route.match('/user/42')        // true
route.match('/product/42')     // false
route.match('/user/42?tab=x')  // true (ignora query)

// Extração
route.extract('/user/42')             // {'id': '42'}
route.extract('/user/42?tab=info')    // {'id': '42'} — ignora query params
route.extract('/user/42#section')     // {'id': '42'} — ignora fragment
route.extract('/product/42')          // null — não faz match

// Construção
route.build({'id': '42'})    // '/user/42'

// Metadados
route.parameters             // ['id']
route.regExp                 // RegExp compilado do padrão
```

**Múltiplos parâmetros:**

```dart
final route = CompilerRoute('/user/:userId/post/:postId');

route.extract('/user/1/post/99')
// {'userId': '1', 'postId': '99'}

route.build({'userId': '1', 'postId': '99'})
// '/user/1/post/99'

route.parameters
// ['userId', 'postId']
```

**Validação de sintaxe:** o construtor lança `FormatException` para padrões inválidos:

```dart
// Válidos
CompilerRoute('/user/:id')
CompilerRoute('/product/:slug')
CompilerRoute('/a/:x/b/:y')

// Inválidos → FormatException
CompilerRoute('/user/:(id')     // parêntese não fechado
CompilerRoute('/user/ :id')     // espaço antes do parâmetro
```

### CAP-UTL-02: Logger

Sistema de logging interno com cores ANSI e integração com DevTools.

**Habilitação:**

```dart
await Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,              // logs do Modugo
  debugLogDiagnosticsGoRouter: true,      // logs do GoRouter
);
```

**Níveis e métodos:**

| Método | Nível | Cor ANSI | Uso |
|---|---|---|---|
| `Logger.information(msg)` | INFO | Azul | Informações gerais |
| `Logger.debug(msg)` | DEBUG | Verde | Debug detalhado |
| `Logger.warn(msg)` | WARN | Amarelo | Avisos não críticos |
| `Logger.error(msg)` | ERROR | Vermelho | Erros |
| `Logger.module(msg)` | MODULE | Ciano | Eventos de módulo |
| `Logger.injection(msg)` | INJECT | Verde | Registro de deps |
| `Logger.dispose(msg)` | DISPOSE | Cinza | Dispose de recursos |
| `Logger.navigation(msg)` | NAVIGATION | Ciano | Navegação |

**Formato de saída:**

```
[14:30:45][MODULE] AppModule binds registered
[14:30:45][INJECT] AuthService registered as singleton
[14:30:46][NAVIGATION] Navigated to /home
[14:30:46][MODULE] ProfileModule skipped (already registered)
```

**Comportamento:**
- Logs são **silenciados** quando `debugLogDiagnostics: false` (padrão de prod)
- Saída dupla: `stdout.writeln` (com ANSI) + `developer.log` (DevTools)
- Em ambientes sem `stdout` (ex: web), falha silenciosamente
- Todos os métodos são estáticos

### CAP-UTL-03: AfterLayoutMixin

Executa um callback após o **primeiro frame** do widget ser renderizado.
Resolve o problema de operar com `BuildContext` em `initState()`.

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Loading...')));

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    // BuildContext válido e widget montado
    await context.read<HomeController>().loadData();
    context.go('/dashboard');
  }
}
```

**Casos de uso:**
- Carregar dados iniciais após montagem
- Mostrar dialogs/snackbars logo ao abrir a tela
- Iniciar animações dependentes do layout
- Navegação automática (ex: splash screen → home)
- Medir widgets após renderização

**Comportamento:**
- `afterFirstLayout()` é chamado **uma única vez** após o primeiro frame
- Verifica `mounted` antes de executar — seguro se o widget for desmontado antes
- Suporta `FutureOr<void>` — pode ser síncrono ou assíncrono

---

## Restrições

- `CompilerRoute.build()` não valida se todos os parâmetros obrigatórios foram fornecidos
- `Logger` requer que `debugLogDiagnostics` esteja `true` — logs são no-op em produção
- `AfterLayoutMixin` deve ser usado apenas em `State<T>` — não em `StatelessWidget`
- `AfterLayoutMixin` usa `WidgetsBinding.instance.addPostFrameCallback()` internamente

---

## Casos de teste obrigatórios

**CompilerRoute:**
- [ ] `match()` retorna true para path correspondente
- [ ] `match()` retorna false para path diferente
- [ ] `extract()` retorna mapa com parâmetros corretos
- [ ] `extract()` ignora query params e fragments
- [ ] `build()` constrói path correto com parâmetros fornecidos
- [ ] Construtor lança `FormatException` para padrão inválido
- [ ] Múltiplos parâmetros são extraídos corretamente

**Logger:**
- [ ] Não emite logs quando `debugLogDiagnostics: false`
- [ ] Emite logs com formato correto quando habilitado

**AfterLayoutMixin:**
- [ ] `afterFirstLayout()` é chamado após o build inicial
- [ ] `afterFirstLayout()` é chamado apenas uma vez
- [ ] Não lança erro se widget for desmontado antes do frame
