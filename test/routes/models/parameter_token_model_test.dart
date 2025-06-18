import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/models/parameter_token_model.dart';

void main() {
  group('ParameterTokenModel', () {
    test('returns correct pattern from toPattern', () {
      final token = ParameterTokenModel('id', pattern: r'[0-9]+');
      expect(token.toPattern(), r'[0-9]+');
    });

    test('returns value from args if valid (default pattern)', () {
      final token = ParameterTokenModel('id');
      final path = token.toPath({'id': '123abc'});

      expect(path, '123abc');
    });

    test('returns value from args if valid (custom pattern)', () {
      final token = ParameterTokenModel('slug', pattern: r'[a-z]+');
      final path = token.toPath({'slug': 'abc'});

      expect(path, 'abc');
    });

    test('throws if value is missing in args', () {
      final token = ParameterTokenModel('sku');
      expect(() => token.toPath({}), throwsArgumentError);
    });

    test('throws if value does not match pattern', () {
      final token = ParameterTokenModel('slug', pattern: r'[a-z]+');
      expect(
        () => token.toPath({'slug': '123'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected "slug" to match "[a-z]+"'),
          ),
        ),
      );
    });

    test('equality: returns true when name and pattern match', () {
      final a = ParameterTokenModel('id', pattern: r'[a-z]+');
      final b = ParameterTokenModel('id', pattern: r'[a-z]+');

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: returns false when name differs', () {
      final a = ParameterTokenModel('id');
      final b = ParameterTokenModel('sku');

      expect(a == b, isFalse);
    });

    test('equality: returns false when pattern differs', () {
      final a = ParameterTokenModel('id', pattern: r'[0-9]+');
      final b = ParameterTokenModel('id', pattern: r'[a-z]+');

      expect(a == b, isFalse);
    });

    test('regExp is compiled correctly', () {
      final token = ParameterTokenModel('id', pattern: r'[0-9]+');
      expect(token.regExp.hasMatch('123'), isTrue);
      expect(token.regExp.hasMatch('abc'), isFalse);
      expect(token.regExp.pattern, r'^[0-9]+$');
    });
  });
}
