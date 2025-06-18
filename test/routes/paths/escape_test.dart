import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/escape.dart';

void main() {
  group('escapeGroup', () {
    test('escapes ":" at start of group', () {
      final result = escapeGroup(':param');
      expect(result, r'\:param');
    });

    test('escapes "=" inside group', () {
      final result = escapeGroup('user=admin');
      expect(result, r'user\=admin');
    });

    test('escapes "!" inside group', () {
      final result = escapeGroup('!secret');
      expect(result, r'\!secret');
    });

    test('escapes only first special character', () {
      final result = escapeGroup(':admin!');
      expect(result, r'\:admin!');
    });

    test('returns original if no matchable character', () {
      final result = escapeGroup('user');
      expect(result, 'user');
    });

    test('returns original for empty string', () {
      final result = escapeGroup('');
      expect(result, '');
    });
  });
}
