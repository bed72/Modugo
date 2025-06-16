import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/dispose.dart';

void main() {
  group('DisposeMilisenconds', () {
    tearDown(() {
      setDisposeMiliseconds(0);
    });

    test('retorna 2000 por padrão se não for definido', () {
      setDisposeMiliseconds(0);
      expect(disposeMilisenconds, 0);
    });

    test('retorna valor customizado após setDisposeMiliseconds', () {
      setDisposeMiliseconds(500);
      expect(disposeMilisenconds, 500);
    });
  });
}
