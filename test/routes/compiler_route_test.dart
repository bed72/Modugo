import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/compiler_route.dart';

void main() {
  group('CompilerRoute success with params', () {
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

  group('CompilerRoute with query params', () {
    test('matches path even with query params', () {
      final compiler = CompilerRoute('/produto/:id');
      expect(compiler.match('/produto/123?foo=bar'), isTrue);
    });

    test('extracts parameters ignoring query params', () {
      final compiler = CompilerRoute('/produto/:id');
      final params = compiler.extract('/produto/123?foo=bar&x=42');
      expect(params, {'id': '123'});
    });

    test(
      'extracts parameters ignoring query params with special characters',
      () {
        final compiler = CompilerRoute('/produto/:id');
        final params = compiler.extract('/produto/ABC%20123?foo=a%20b');
        expect(params, {'id': 'ABC%20123'});
      },
    );

    test('does not match if path before query is different', () {
      final compiler = CompilerRoute('/produto/:id');
      expect(compiler.match('/categoria/123?foo=bar'), isFalse);
    });

    test('still builds valid path without query params', () {
      final compiler = CompilerRoute('/produto/:id');
      final path = compiler.build({'id': 'ABC%20123'});
      expect(path, '/produto/ABC%20123');
    });
  });

  group('CompilerRoute failure', () {
    test('throws FormatException for invalid parameter syntax (:(id)', () {
      expect(
        () => CompilerRoute('/produto/:(id'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'throws FormatException for invalid parameter starting with number',
      () {
        expect(
          () => CompilerRoute('/produto/:1abc'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('throws FormatException for double colon parameter (::id)', () {
      expect(
        () => CompilerRoute('/produto/::id'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when pattern contains spaces', () {
      expect(
        () => CompilerRoute('/produto/:id nome'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
