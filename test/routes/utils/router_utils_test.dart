import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/routes/utils/router_utils.dart';

void main() {
  group('ensureLeadingSlash', () {
    test('should add leading slash if missing', () {
      expect(ensureLeadingSlash('home'), equals('/home'));
    });

    test('should keep leading slash if already present', () {
      expect(ensureLeadingSlash('/settings'), equals('/settings'));
    });
  });

  group('hasEmbeddedParams', () {
    test('should return true if path contains embedded parameter', () {
      expect(hasEmbeddedParams('/user/:id'), isTrue);
    });

    test('should return false if path does not contain parameter', () {
      expect(hasEmbeddedParams('/products'), isFalse);
    });
  });

  group('normalizePath', () {
    test('should remove duplicate slashes and trailing slash', () {
      expect(normalizePath('///home///products//'), equals('/home/products'));
    });

    test('should return root slash as-is', () {
      expect(normalizePath('/'), equals('/'));
    });
  });

  group('removeDuplicatedPrefix', () {
    test('should remove module prefix from routeName if present', () {
      expect(removeDuplicatedPrefix('home', 'home/details'), equals('details'));
    });

    test('should return original routeName if module prefix not present', () {
      expect(
        removeDuplicatedPrefix('profile', 'settings/details'),
        equals('settings/details'),
      );
    });
  });
}
