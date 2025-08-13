import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/models/path_token_model.dart';

void main() {
  group('PathTokenModel', () {
    test('returns value directly from toPath', () {
      final token = PathTokenModel('/home');
      final result = token.toPath({});
      expect(result, '/home');
    });

    test('returns escaped value from toPattern', () {
      final token = PathTokenModel('/user/:id');
      final result = token.toPattern();

      expect(result, r'/user/:id');
    });

    test('equality: returns true for same value', () {
      final a = PathTokenModel('/a/b');
      final b = PathTokenModel('/a/b');

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: returns false for different value', () {
      final a = PathTokenModel('/home');
      final b = PathTokenModel('/about');

      expect(a == b, isFalse);
    });

    test('is immutable and supports const', () {
      const a = PathTokenModel('/home');
      const b = PathTokenModel('/home');

      expect(identical(a, b), isTrue);
    });
  });
}
