import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/function.dart';

import 'package:modugo/src/routes/models/path_token_model.dart';
import 'package:modugo/src/routes/models/parameter_token_model.dart';

void main() {
  group('tokensToFunction', () {
    test('builds static path from PathTokenModel', () {
      final fn = tokensToFunction([const PathTokenModel('/home')]);

      expect(fn({}), '/home');
    });

    test('builds dynamic path from ParameterTokenModel', () {
      final fn = tokensToFunction([
        const PathTokenModel('/user/'),
        ParameterTokenModel('id'),
      ]);

      final result = fn({'id': 'abc123'});
      expect(result, '/user/abc123');
    });

    test('throws if parameter is missing', () {
      final fn = tokensToFunction([
        const PathTokenModel('/product/'),
        ParameterTokenModel('sku'),
      ]);

      expect(() => fn({}), throwsArgumentError);
    });

    test('throws if parameter doesn\'t match pattern', () {
      final fn = tokensToFunction([
        const PathTokenModel('/tag/'),
        ParameterTokenModel('slug', pattern: r'[a-z]+'),
      ]);

      expect(() => fn({'slug': 'ABC123'}), throwsArgumentError);
    });

    test('builds with multiple tokens (mixed)', () {
      final fn = tokensToFunction([
        const PathTokenModel('/p/'),
        ParameterTokenModel('user'),
        const PathTokenModel('/post/'),
        ParameterTokenModel('id'),
      ]);

      final path = fn({'user': 'maria', 'id': '42'});
      expect(path, '/p/maria/post/42');
    });
  });

  group('pathToFunction', () {
    test('builds path from string with static segments', () {
      final fn = pathToFunction('/settings');
      expect(fn({}), '/settings');
    });

    test('builds path from string with dynamic parameter', () {
      final fn = pathToFunction('/produto/:id');
      expect(fn({'id': 'X7'}), '/produto/X7');
    });

    test('throws if argument is missing', () {
      final fn = pathToFunction('/p/:name');
      expect(() => fn({}), throwsArgumentError);
    });

    test('throws if argument is invalid for regex', () {
      final fn = pathToFunction('/t/:slug([a-z]+)');
      expect(() => fn({'slug': 'ABC'}), throwsArgumentError);
    });
  });
}
