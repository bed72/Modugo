## 1. Implementação

- [x] 1.1 `lib/src/module.dart`: remover `async` da declaração `void _configureBinders({IBinder? binder}) async`

## 2. Testes

- [ ] 2.1 Adicionar teste em `test/modules/module_test.dart`:
  exceção em `binds()` de módulo importado propaga para `configureRoutes()`

## 3. CI

- [x] 3.1 Rodar `flutter test` — 0 falhas
- [x] 3.2 Rodar `flutter analyze` — 0 issues
