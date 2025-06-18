import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/paths/path.dart';

void main() {
  group('ensureLeadingSlash', () {
    test('adds slash when missing', () {
      expect(ensureLeadingSlash('abc'), '/abc');
    });

    test('does not add slash if already present', () {
      expect(ensureLeadingSlash('/abc'), '/abc');
    });

    test('works with empty string', () {
      expect(ensureLeadingSlash(''), '/');
    });
  });

  group('hasEmbeddedParams', () {
    test('detects embedded param with colon', () {
      expect(hasEmbeddedParams('/produto/:id'), isTrue);
      expect(hasEmbeddedParams('/user/:userId/details'), isTrue);
    });

    test('returns false for static routes', () {
      expect(hasEmbeddedParams('/home'), isFalse);
      expect(hasEmbeddedParams('/user/details'), isFalse);
    });
  });

  group('normalizePath', () {
    test('removes repeated slashes', () {
      expect(normalizePath('/a//b///c'), '/a/b/c');
    });

    test('ensures trailing slash if not root', () {
      expect(normalizePath('/abc'), '/abc');
      expect(normalizePath('/abc/'), '/abc');
    });

    test('keeps only root slash as-is', () {
      expect(normalizePath('/'), '/');
    });

    test('removes trailing slash except for root', () {
      expect(normalizePath('/abc/'), '/abc');
      expect(normalizePath('/abc///'), '/abc');
    });
  });

  group('removeDuplicatedPrefix', () {
    test('removes prefix if present', () {
      expect(removeDuplicatedPrefix('/module', '/module/home'), 'home');
      expect(removeDuplicatedPrefix('/user', '/user/:id'), ':id');
    });

    test('removes extra slash if needed', () {
      expect(removeDuplicatedPrefix('/prefix', '/prefix//sub'), '/sub');
    });

    test('returns route unchanged if prefix not found', () {
      expect(removeDuplicatedPrefix('/auth', '/home'), '/home');
    });

    test('works when route is equal to prefix', () {
      expect(removeDuplicatedPrefix('/abc', '/abc'), '');
    });
  });
}
