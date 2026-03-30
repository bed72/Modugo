## 1. Dependência

- [x] 1.1 Adicionar `async: ^2.12.0` em `dependencies` no `pubspec.yaml`
- [x] 1.2 Rodar `flutter pub get` e verificar que não há conflitos de versão

## 2. Refatoração de `FactoryRoute`

- [x] 2.1 Adicionar import `package:async/async.dart` em `lib/src/routes/factory_route.dart`
- [x] 2.2 Declarar campo estático `static CancelableOperation<String?>? _pendingGuards` em `FactoryRoute`
- [x] 2.3 Extrair o loop de guards atual de `_executeGuards` para novo método estático `_runGuards({required BuildContext context, required List<IGuard> guards, required GoRouterState state})`
- [x] 2.4 Reescrever `_executeGuards` para: cancelar `_pendingGuards` anterior, criar `CancelableOperation.fromFuture(_runGuards(...))`, atribuir a `_pendingGuards`, e retornar `operation.valueOrCancellation(null)`

## 3. Testes de concorrência

- [x] 3.1 Criar `test/guards/guard_concurrency_test.dart` com estrutura de grupo e setUp
- [x] 3.2 Teste: execução única sem concorrência — guard retorna `null` → resultado preservado
- [x] 3.3 Teste: execução única sem concorrência — guard retorna path → resultado preservado
- [x] 3.4 Teste: segunda chamada a `_executeGuards` chega antes da primeira completar → primeira retorna `null`
- [x] 3.5 Teste: guard com redirect (`'/login'`) é cancelado por segunda chamada → primeira retorna `null`, segunda retorna seu próprio resultado
- [x] 3.6 Teste: múltiplos guards em sequência sem concorrência — todos executam, primeiro non-null vence
- [x] 3.7 Teste: cancelamento entre guards — segundo guard não é invocado quando operação é cancelada após o primeiro completar
- [x] 3.8 Teste: três chamadas em sequência rápida — apenas a última entrega resultado
- [x] 3.9 Teste: guard que lança exceção sem concorrência — erro é logado e relançado (comportamento atual preservado)
- [x] 3.10 Teste: guard que lança exceção em chamada cancelada — `_executeGuards` retorna `null` sem propagar exceção
- [x] 3.11 Teste: guard assíncrono (com `Completer`) sem cancelamento — resultado entregue corretamente
- [x] 3.12 Teste: guard assíncrono cancelado mid-flight — retorna `null` mesmo que o Future subjacente ainda resolva depois

## 4. Verificação

- [x] 4.1 Rodar `flutter test test/guards/` e confirmar que todos os testes passam
- [x] 4.2 Rodar `flutter test` completo e confirmar que nenhum teste existente regrediu
- [x] 4.3 Rodar `flutter analyze` e confirmar zero warnings
- [x] 4.4 Rodar `dart format --set-exit-if-changed lib test` e confirmar formatação correta
