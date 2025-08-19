import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/uri_extension.dart';

void main() {
  group('UriPathWithExtras.fullPath', () {
    test('should return only path when no query and no fragment', () {
      final uri = Uri.parse('https://example.com/login.do');
      expect(uri.fullPath, equals('/login.do'));
    });

    test('should return path with query when query exists', () {
      final uri = Uri.parse('https://example.com/login.do?foo=bar&baz=123');
      expect(uri.fullPath, equals('/login.do?foo=bar&baz=123'));
    });

    test('should return path with fragment when fragment exists', () {
      final uri = Uri.parse('https://example.com/login.do#section1');
      expect(uri.fullPath, equals('/login.do#section1'));
    });

    test('should return path with query and fragment when both exist', () {
      final uri = Uri.parse('https://example.com/login.do?foo=bar#frag');
      expect(uri.fullPath, equals('/login.do?foo=bar#frag'));
    });

    test('should handle query without value correctly', () {
      final uri = Uri.parse('https://example.com/page?flag=');
      expect(uri.fullPath, equals('/page?flag='));
    });

    test('should handle fragment only correctly', () {
      final uri = Uri.parse('https://example.com/#top');
      expect(uri.fullPath, equals('/#top'));
    });
  });

  group('Uri query utils', () {
    test('hasQueryParam returns true when key exists', () {
      final uri = Uri.parse('https://example.com/page?foo=bar');
      expect(uri.hasQueryParam('foo'), isTrue);
      expect(uri.hasQueryParam('baz'), isFalse);
    });

    test('getQueryParam returns value if exists', () {
      final uri = Uri.parse('https://example.com/page?foo=bar');
      expect(uri.getQueryParam('foo'), equals('bar'));
    });

    test('getQueryParam returns defaultValue if key does not exist', () {
      final uri = Uri.parse('https://example.com/page');
      expect(
        uri.getQueryParam('missing', defaultValue: 'default'),
        equals('default'),
      );
    });
  });

  group('Uri path utils', () {
    test('isSubPathOf returns true for subpath', () {
      final parent = Uri.parse('https://example.com/product');
      final child = Uri.parse('https://example.com/product/123');
      expect(child.isSubPathOf(parent), isTrue);
    });

    test('isSubPathOf returns false if not subpath', () {
      final parent = Uri.parse('https://example.com/product');
      final other = Uri.parse('https://example.com/category/123');
      expect(other.isSubPathOf(parent), isFalse);
    });

    test('withAppendedPath appends correctly when no trailing slash', () {
      final uri = Uri.parse('https://example.com/user');
      expect(
        uri.withAppendedPath('profile').toString(),
        equals('https://example.com/user/profile'),
      );
    });

    test('withAppendedPath appends correctly when trailing slash exists', () {
      final uri = Uri.parse('https://example.com/user/');
      expect(
        uri.withAppendedPath('profile').toString(),
        equals('https://example.com/user/profile'),
      );
    });
  });
}
