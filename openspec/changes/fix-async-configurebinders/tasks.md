## 1. Implementação

- [ ] 1.1 `lib/src/module.dart`: remover `async` da declaração `void _configureBinders({IBinder? binder}) async`

## 2. Testes

- [ ] 2.1 Adicionar teste em `test/modules/module_test.dart`:
  exceção em `binds()` de módulo importado propaga para `configureRoutes()`

## 3. CI

- [ ] 3.1 Rodar `flutter test` — 0 falhas
- [ ] 3.2 Rodar `flutter analyze` — 0 issues
