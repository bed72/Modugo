import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/extract.dart';

void main() {
  group('extract', () {
    test('extracts single parameter match', () {
      final parameters = ['id'];
      final regExp = RegExp(r'^/produto/([^/]+)$');
      final match = regExp.firstMatch('/produto/abc123')!;

      final result = extract(parameters, match);
      expect(result, {'id': 'abc123'});
    });

    test('extracts multiple parameters', () {
      final parameters = ['user', 'post'];
      final regExp = RegExp(r'^/u/([^/]+)/p/([^/]+)$');
      final match = regExp.firstMatch('/u/maria/p/42')!;

      final result = extract(parameters, match);
      expect(result, {'user': 'maria', 'post': '42'});
    });

    test('returns empty map for no parameters', () {
      final parameters = <String>[];
      final regExp = RegExp(r'^/home$');
      final match = regExp.firstMatch('/home')!;

      final result = extract(parameters, match);
      expect(result, isEmpty);
    });

    test('ignores additional groups if parameters list is shorter', () {
      final parameters = ['id'];
      final regExp = RegExp(r'^/p/([^/]+)/([^/]+)$');
      final match = regExp.firstMatch('/p/abc123/extra')!;

      final result = extract(parameters, match);
      expect(result, {'id': 'abc123'});
    });
  });
}
