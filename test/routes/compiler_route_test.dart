import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/compiler_route.dart';

void main() {
  group('CompilerRoute', () {
    test('matches path with parameter', () {
      final compiler = CompilerRoute('/produto/:id');
      expect(compiler.match('/produto/123'), isTrue);
    });

    test('does not match invalid path', () {
      final compiler = CompilerRoute('/produto/:id');
      expect(compiler.match('/categoria/123'), isFalse);
    });

    test('extracts parameters from matching path', () {
      final compiler = CompilerRoute('/produto/:id');
      final params = compiler.extract('/produto/abc');
      expect(params, {'id': 'abc'});
    });

    test('returns null for non-matching path in extract', () {
      final compiler = CompilerRoute('/produto/:id');
      expect(compiler.extract('/outra/rota'), isNull);
    });

    test('builds path from parameters', () {
      final compiler = CompilerRoute('/produto/:id');
      final path = compiler.build({'id': 'X9'});
      expect(path, '/produto/X9');
    });

    test('parameters returns parameter names', () {
      final compiler = CompilerRoute('/produto/:id');
      compiler.match('/produto/123');
      expect(compiler.parameters, ['id']);
    });
  });
}
