# 🧩 Injeção de Dependências

O Modugo possui um **sistema de DI baseado no GetIt**, permitindo registrar e acessar instâncias de serviços de forma centralizada dentro de módulos. Isso facilita a modularização, testes e reutilização de código.

---

## 🔹 Registrando Dependências

Dentro de cada módulo, você pode registrar **binds** usando o método `binds()`:

```dart
final class HomeModule extends Module {
  @override
  List<IBinder> imports() => [CoreModule()]; // importa outros módulos se necessário

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (context, state) => const HomePage()),
  ];

  @override
  void binds() {
    i
      ..registerSingleton<ServiceRepository>(ServiceRepository.instance) // singleton
      ..registerLazySingleton<OtherServiceRepository>(OtherServiceRepositoryImpl.new); // lazy singleton
  }
}
```

### ✅ Tipos de registro suportados:

- `registerSingleton<T>(instance)` → Instância única já criada, retornada sempre que requisitada.
- `registerLazySingleton<T>(factory)` → Instância criada apenas na primeira vez que for requisitada.
- `registerFactory<T>(factory)` → Cria uma nova instância a cada requisição.

> 🔹 Observação: `i` é o **Injector do Modugo**, equivalente ao `GetIt.I` no GetIt.

---

## 🔹 Acessando Dependências

Para obter uma instância registrada dentro do módulo ou de qualquer widget que faça parte do módulo:

```dart
final service = i.get<ServiceRepository>();
final service = Modugo.i.get<ServiceRepository>();
final otherService = context.read<OtherServiceRepository>();
```

> 🔹 Funciona de forma global dentro do escopo do módulo, garantindo consistência e fácil substituição para testes.

---

## 🔹 Comparação com GetIt

Se você já conhece o GetIt, o fluxo é muito parecido:

```dart
// GetIt
final getIt = GetIt.instance;
getIt.registerSingleton<ServiceRepository>(ServiceRepository.instance);

// Modugo
i.registerSingleton<ServiceRepository>(ServiceRepository.instance);
```

**Diferenças principais:**

- Suporte direto a **rotas modulares**, resolvendo binds automaticamente ao acessar uma rota.

---

## 🔹 Ciclo de Vida e Modularidade

- **Lazy Singleton e Factory** são criados **sob demanda**, economizando memória.
- **Singleton** pode ser compartilhado entre módulos importados.
- Cada módulo pode importar outros módulos, mantendo a **hierarquia de dependências** limpa e previsível.

---

## 🔹 Exemplo Visual de DI

```
[HomeModule] ---> Singleton(ServiceRepository)
              \-> LazySingleton(OtherServiceRepository)

[ProfileModule] ---> importa HomeModule
                     Singleton(ServiceRepository) já compartilhado
                     LazySingleton(ProfileService)
```

> Visualiza como singleton é compartilhado e lazy/factory são criados sob demanda.

---

## 🔹 Acesso via Context Extension

Alem de `i.get<T>()` e `Modugo.i.get<T>()`, voce pode usar as extensions de `BuildContext`:

### `context.read<T>()`

Recupera uma dependência registrada de forma síncrona:

```dart
final controller = context.read<HomeController>();

// Com instância nomeada
final primaryDb = context.read<Database>(instanceName: 'primary');
```

### `context.readAsync<T>()`

Recupera dependências registradas de forma assíncrona (via `registerSingletonAsync`):

```dart
final service = await context.readAsync<MyService>();
```

### Parâmetros opcionais

| Parâmetro | Descrição |
|-----------|-----------|
| `param1` | Primeiro parâmetro para factories parametrizadas |
| `param2` | Segundo parâmetro para factories parametrizadas |
| `type` | Tipo específico para resolver quando há múltiplas implementações |
| `instanceName` | Nome da instância registrada |
