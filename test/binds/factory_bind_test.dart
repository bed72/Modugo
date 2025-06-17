import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/injector.dart';
import 'package:modugo/src/binds/factory_bind.dart';
import 'package:modugo/src/interfaces/bind_interface.dart';

void main() {
  late IBind<_Dependency> bind;

  setUp(() {
    bind = FactoryBind(
      (_) => _Dependency(DateTime.now().millisecondsSinceEpoch),
    );
  });

  test('get() returns a new instance every time', () {
    final first = bind.get(Injector());
    final second = bind.get(Injector());

    expect(first, isNot(same(second)));
    expect(first.runtimeType, _Dependency);
    expect(second.runtimeType, _Dependency);
  });

  test('dispose() does not throw and does not affect get()', () {
    bind.dispose();

    final instance = bind.get(Injector());
    expect(instance, isA<_Dependency>());
  });
}

final class _Dependency {
  final int value;
  _Dependency(this.value);
}
