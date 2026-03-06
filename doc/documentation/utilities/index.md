# 🛠️ Utilitários

O Modugo inclui um conjunto de utilitários auxiliares para tarefas comuns no desenvolvimento Flutter.

---

## 🔹 AfterLayoutMixin

Mixin que executa um callback **após o primeiro frame** do widget ser renderizado. Útil quando você precisa de um `BuildContext` válido para operações pós-layout.

### Quando usar

- Carregar dados iniciais (trigger de Cubit/Bloc/Controller).
- Mostrar dialogs ou snackbars logo após a tela abrir.
- Iniciar animações que dependem do layout renderizado.
- Realizar medições de widgets.

### Exemplo

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Hello World')),
    );
  }

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    // Contexto válido - seguro para navegar, mostrar dialogs, etc.
    debugPrint('Tela pronta!');

    // Exemplo: carregar dados
    context.read<HomeController>().loadData();
  }
}
```

### Comportamento

- `afterFirstLayout` é chamado **uma única vez**, após o primeiro frame.
- Verifica `mounted` antes de executar, evitando erros se o widget for desmontado.
- Suporta operações síncronas e assíncronas (`FutureOr<void>`).

---

## 🔹 CompilerRoute

Utilitário para validar, compilar e manipular padrões de rotas dinâmicas. Usa a biblioteca `path_to_regexp` internamente.

### API

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `match(path)` | `bool` | Verifica se o path corresponde ao padrão |
| `extract(path)` | `Map<String, String>?` | Extrai parâmetros do path |
| `build(args)` | `String` | Constrói um path concreto a partir de parâmetros |
| `parameters` | `List<String>` | Lista de nomes dos parâmetros |
| `regExp` | `RegExp` | Expressão regular compilada |

### Exemplos

```dart
final route = CompilerRoute('/user/:id');

route.match('/user/42');       // true
route.match('/product/42');    // false

route.extract('/user/42');     // {'id': '42'}
route.extract('/product/42');  // null

route.build({'id': '42'});     // '/user/42'
route.parameters;              // ['id']
```

### Múltiplos parâmetros

```dart
final route = CompilerRoute('/user/:id/post/:postId');

route.extract('/user/1/post/99');
// {'id': '1', 'postId': '99'}

route.build({'id': '1', 'postId': '99'});
// '/user/1/post/99'

route.parameters;
// ['id', 'postId']
```

### Validação de padrões

O `CompilerRoute` valida a sintaxe do padrão na construção:

```dart
// Válidos
CompilerRoute('/user/:id');
CompilerRoute('/product/:slug');
CompilerRoute('/user/:userId');

// Inválidos - lançam FormatException
CompilerRoute('/user/:(id');    // Sintaxe inválida
CompilerRoute('/user/ :id');    // Espaço no path
```

### Query params e fragments

O `extract` ignora query params e fragments automaticamente:

```dart
final route = CompilerRoute('/user/:id');

route.extract('/user/42?tab=info');     // {'id': '42'}
route.extract('/user/42#section');      // {'id': '42'}
route.extract('/user/42?q=1#top');      // {'id': '42'}
```

---

## 🔹 Logger

Sistema de logging interno do Modugo com cores ANSI e integração com DevTools.

### Habilitando

```dart
await Modugo.configure(
  module: AppModule(),
  debugLogDiagnostics: true,
);
```

### Métodos disponíveis

| Método | Nível | Cor |
|--------|-------|-----|
| `Logger.information(msg)` | INFO | Azul |
| `Logger.debug(msg)` | DEBUG | Verde |
| `Logger.warn(msg)` | WARN | Amarelo |
| `Logger.error(msg)` | ERROR | Vermelho |
| `Logger.module(msg)` | MODULE | Ciano |
| `Logger.injection(msg)` | INJECT | Verde |
| `Logger.dispose(msg)` | DISPOSE | Cinza |
| `Logger.navigation(msg)` | NAVIGATION | Ciano |

### Comportamento

- Logs são **silenciados** quando `debugLogDiagnostics` é `false` (padrão).
- Saída formatada com timestamp: `[HH:mm:ss][LEVEL] mensagem`.
- Envia logs para:
  - **Console** via `stdout.writeln` (com cores ANSI).
  - **DevTools** via `developer.log`.
- Em ambientes sem `stdout` (ex: web), falha silenciosamente.

### Formato de saída

```
[14:30:45][MODULE] AppModule binds registered
[14:30:45][INJECT] AuthService registered as singleton
[14:30:46][NAVIGATION] Navigated to /home
```
