import 'package:modugo/src/injector.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

final class FactoryBind<T> implements IBind<T> {
  final T Function(Injector i) _builder;

  FactoryBind(this._builder);

  @override
  T get(Injector i) => _builder(i);

  @override
  void dispose() {
    if (Modugo.debugLogDiagnostics) {
      ModugoLogger.info('[FACTORY] dispose() called, but no action taken.');
    }
  }
}
