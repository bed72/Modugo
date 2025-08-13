import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/regexp.dart';

import 'package:modugo/src/models/path_token_model.dart';
import 'package:modugo/src/models/parameter_token_model.dart';

void main() {
  group('pathToRegExp', () {
    test('matches static path', () {
      final regex = pathToRegExp('/home');
      expect(regex.hasMatch('/home'), isTrue);
      expect(regex.hasMatch('/home/abc'), isFalse);
      expect(regex.pattern, '^/home\$');
    });

    test('matches path with one parameter', () {
      final regex = pathToRegExp('/user/:id');
      expect(regex.hasMatch('/user/123'), isTrue);
      expect(regex.hasMatch('/user/'), isFalse);
      expect(regex.hasMatch('/user'), isFalse);
    });

    test('fills parameter list if provided', () {
      final params = <String>[];
      pathToRegExp('/p/:name/:id', parameters: params);
      expect(params, ['name', 'id']);
    });

    test('supports prefix = true', () {
      final regex = pathToRegExp('/produtos/:id', prefix: true);
      expect(regex.hasMatch('/produtos/123'), isTrue);
      expect(regex.hasMatch('/produtos/123/details'), isTrue);
    });

    test('respects case sensitivity', () {
      final regex = pathToRegExp('/Tag/:slug');
      expect(regex.hasMatch('/tag/abc'), isFalse);

      final insensitive = pathToRegExp('/Tag/:slug', caseSensitive: false);
      expect(insensitive.hasMatch('/tag/abc'), isTrue);
    });
  });

  group('tokensToRegExp', () {
    test('builds regex from static token', () {
      final regex = tokensToRegExp([const PathTokenModel('/about')]);

      expect(regex.pattern, '^/about\$');
      expect(regex.hasMatch('/about'), isTrue);
      expect(regex.hasMatch('/aboutus'), isFalse);
    });

    test('builds regex with dynamic token', () {
      final regex = tokensToRegExp([
        const PathTokenModel('/user/'),
        ParameterTokenModel('id'),
      ]);

      expect(regex.hasMatch('/user/abc'), isTrue);
      expect(regex.hasMatch('/user/'), isFalse);
    });

    test('handles prefix=true with trailing slash', () {
      final regex = tokensToRegExp([
        const PathTokenModel('/docs/'),
      ], prefix: true);

      expect(regex.hasMatch('/docs/123'), isTrue);
      expect(regex.pattern, '^/docs/');
    });

    test('handles prefix=true without trailing slash', () {
      final regex = tokensToRegExp([
        const PathTokenModel('/docs'),
      ], prefix: true);

      expect(regex.hasMatch('/docs/123'), isTrue);
      expect(regex.pattern, '^/docs(?=/|\$)');
    });

    test('handles prefix=true without trailing slash', () {
      final regex = tokensToRegExp([
        const PathTokenModel('/docs'),
      ], prefix: true);

      expect(regex.hasMatch('/docs'), isTrue);
      expect(regex.hasMatch('/docs/details'), isTrue);
      expect(regex.pattern, '^/docs(?=/|\$)');
    });
  });
}
