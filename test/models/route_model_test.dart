import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/models/route_model.dart';

void main() {
  group('RouteModuleModel - equality and hashCode', () {
    test('should be equal when all fields are equal', () {
      const a = RouteModuleModel(
        name: 'home',
        route: '/home',
        params: ['id'],
        module: '/home/',
        child: '/home/:id',
        transition: TypeTransition.fade,
      );

      const b = RouteModuleModel(
        name: 'home',
        route: '/home',
        params: ['id'],
        module: '/home/',
        child: '/home/:id',
        transition: TypeTransition.fade,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal when params differ', () {
      const a = RouteModuleModel(
        name: 'home',
        route: '/home',
        params: ['id'],
        module: '/home/',
        child: '/home/:id',
      );

      const b = RouteModuleModel(
        name: 'home',
        route: '/home',
        module: '/home/',
        child: '/home/:id',
        params: ['userId'],
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('RouteModuleModel - static build()', () {
    test('should build model with expected properties', () {
      final model = RouteModuleModel.build(
        module: 'home',
        params: ['id'],
        routeName: 'home/details',
      );

      expect(model.params, equals(['id']));
      expect(model.name, equals('details'));
      expect(model.module, equals('/home'));
      expect(model.child, equals('/details/:id'));
    });

    test('should handle trailing slashes in routeName', () {
      final model = RouteModuleModel.build(module: 'profile', routeName: '/');

      expect(model.child, equals('/'));
      expect(model.name, equals('profile'));
      expect(model.route, equals('/profile'));
    });

    test(
      'should build child and route with empty routeName (equal to module)',
      () {
        final model = RouteModuleModel.build(
          module: 'settings',
          routeName: 'settings',
        );

        expect(model.child, equals('/'));
        expect(model.name, equals('settings'));
        expect(model.route, equals('/settings'));
      },
    );
  });

  group('RouteModuleModel - buildPath()', () {
    test('should build path replacing parameters and subparams', () {
      final model = RouteModuleModel(
        params: ['id'],
        name: 'example',
        route: '/route',
        module: '/module',
        child: '/details/:id',
      );

      final result = model.buildPath(params: ['123'], subParams: ['deep']);

      expect(result, equals('/module/deep/details/123'));
    });

    test('should ignore :id if not in child', () {
      final model = RouteModuleModel(
        name: 'test',
        child: '/home',
        module: '/base',
        route: '/route',
      );

      final result = model.buildPath(params: ['1', '2'], subParams: ['x']);

      expect(result, equals('/base/x/home/1/2'));
    });
  });

  group('RouteModuleModel - toString()', () {
    test('should return expected string', () {
      const model = RouteModuleModel(
        name: 'test',
        params: ['id'],
        route: '/route',
        child: '/child',
        module: '/module',
      );

      expect(
        model.toString(),
        equals(
          'RouteModuleModel(module: /module, child: /child, route: /route, params: [id])',
        ),
      );
    });
  });

  group('RouteModuleModel - resolvePath()', () {
    test('should normalize redundant slashes and remove trailing slash', () {
      final result = RouteModuleModel.resolvePath('///home///profile//');
      expect(result, equals('/home/profile'));
    });

    test('should return root slash as-is', () {
      final result = RouteModuleModel.resolvePath('/');
      expect(result, equals('/'));
    });
  });

  group('RouteModuleModel - extractName()', () {
    test('should extract first segment from path', () {
      final name = RouteModuleModel.extractName('/home/details');
      expect(name, equals('home'));
    });

    test('should return full path when no segment is matched', () {
      final name = RouteModuleModel.extractName('');
      expect(name, equals('/'));
    });
  });

  group('RouteModuleModel.ensureLeadingSlash', () {
    test('adds slash when missing', () {
      expect(RouteModuleModel.ensureLeadingSlash('abc'), '/abc');
    });

    test('does not add slash if already present', () {
      expect(RouteModuleModel.ensureLeadingSlash('/abc'), '/abc');
    });

    test('works with empty string', () {
      expect(RouteModuleModel.ensureLeadingSlash(''), '/');
    });
  });

  group('RouteModuleModel.hasEmbeddedParams', () {
    test('detects embedded param with colon', () {
      expect(RouteModuleModel.hasEmbeddedParams('/produto/:id'), isTrue);
      expect(
        RouteModuleModel.hasEmbeddedParams('/user/:userId/details'),
        isTrue,
      );
    });

    test('returns false for static routes', () {
      expect(RouteModuleModel.hasEmbeddedParams('/home'), isFalse);
      expect(RouteModuleModel.hasEmbeddedParams('/user/details'), isFalse);
    });
  });

  group('RouteModuleModel.normalizePath', () {
    test('removes repeated slashes', () {
      expect(RouteModuleModel.normalizePath('/a//b///c'), '/a/b/c');
    });

    test('ensures trailing slash if not root', () {
      expect(RouteModuleModel.normalizePath('/abc'), '/abc');
      expect(RouteModuleModel.normalizePath('/abc/'), '/abc');
    });

    test('keeps only root slash as-is', () {
      expect(RouteModuleModel.normalizePath('/'), '/');
    });

    test('removes trailing slash except for root', () {
      expect(RouteModuleModel.normalizePath('/abc/'), '/abc');
      expect(RouteModuleModel.normalizePath('/abc///'), '/abc');
    });
  });

  group('RouteModuleModel.removeDuplicatedPrefix', () {
    test('removes prefix if present', () {
      expect(
        RouteModuleModel.removeDuplicatedPrefix('/module', '/module/home'),
        'home',
      );
      expect(
        RouteModuleModel.removeDuplicatedPrefix('/user', '/user/:id'),
        ':id',
      );
    });

    test('removes extra slash if needed', () {
      expect(
        RouteModuleModel.removeDuplicatedPrefix('/prefix', '/prefix//sub'),
        '/sub',
      );
    });

    test('returns route unchanged if prefix not found', () {
      expect(
        RouteModuleModel.removeDuplicatedPrefix('/auth', '/home'),
        '/home',
      );
    });

    test('works when route is equal to prefix', () {
      expect(RouteModuleModel.removeDuplicatedPrefix('/abc', '/abc'), '');
    });
  });
}
