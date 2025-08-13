import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/parse.dart';

import 'package:modugo/src/models/path_token_model.dart';
import 'package:modugo/src/models/parameter_token_model.dart';

void main() {
  group('parse', () {
    test('parses static-only path', () {
      final tokens = parse('/home');

      expect(tokens.length, 1);
      expect(tokens[0], isA<PathTokenModel>());
      expect((tokens[0] as PathTokenModel).value, '/home');
    });

    test('parses single parameter', () {
      final tokens = parse('/user/:id');

      expect(tokens.length, 2);
      expect(tokens[0], isA<PathTokenModel>());
      expect((tokens[0] as PathTokenModel).value, '/user/');

      expect(tokens[1], isA<ParameterTokenModel>());
      expect((tokens[1] as ParameterTokenModel).name, 'id');
      expect((tokens[1] as ParameterTokenModel).pattern, r'([^/]+?)');
    });

    test('parses multiple parameters and statics', () {
      final tokens = parse('/u/:user/p/:post');

      expect(tokens.length, 4);

      expect(tokens[0], isA<PathTokenModel>());
      expect((tokens[1] as ParameterTokenModel).name, 'user');
      expect(tokens[2], isA<PathTokenModel>());
      expect((tokens[3] as ParameterTokenModel).name, 'post');
    });

    test('parses parameter with custom pattern', () {
      final tokens = parse('/tag/:slug([a-z]+)');

      final param = tokens[1] as ParameterTokenModel;

      expect(param.name, 'slug');
      expect(param.pattern, '([a-z]+)');
      expect(param.regExp.pattern, '^([a-z]+)\$');
    });

    test('parses with parameter list output', () {
      final names = <String>[];
      parse('/p/:id/:type', parameters: names);

      expect(names, ['id', 'type']);
    });

    test('returns empty list for empty string', () {
      final tokens = parse('');
      expect(tokens, isEmpty);
    });
  });
}
