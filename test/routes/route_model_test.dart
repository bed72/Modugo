import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/transition.dart';
import 'package:modugo/src/routes/models/route_model.dart';

void main() {
  test('instance with default values', () {
    final model = RouteModuleModel(
      route: '/home',
      module: '/home',
      child: '/home/:id',
    );

    expect(model.name, '');
    expect(model.params, isNull);
    expect(model.transition, TypeTransition.fade);
  });

  test('instance with custom values', () {
    final model = RouteModuleModel(
      name: 'home',
      params: ['id'],
      route: '/home',
      module: '/home',
      child: '/home/:id',
      transition: TypeTransition.slideDown,
    );

    expect(model.name, 'home');
    expect(model.params, ['id']);
    expect(model.transition, TypeTransition.slideDown);
  });

  test('use Equatable correctly (==)', () {
    final model1 = RouteModuleModel(
      name: 'home',
      params: ['id'],
      route: '/home',
      module: '/home',
      child: '/home/:id',
      transition: TypeTransition.fade,
    );

    final model2 = RouteModuleModel(
      name: 'home',
      params: ['id'],
      route: '/home',
      module: '/home',
      child: '/home/:id',
      transition: TypeTransition.fade,
    );

    expect(model1, equals(model2));
  });

  test('toString returns expected value', () {
    final model = RouteModuleModel(
      route: '/home',
      params: ['id'],
      module: '/home',
      child: '/home/:id',
    );

    expect(
      model.toString(),
      'RouteModuleModel(module: /home, child: /home/:id, route: /home, params: [id])',
    );
  });

  test('buildPath builds the path correctly', () {
    final model = RouteModuleModel(
      route: '/products',
      module: '/products',
      child: '/products/:category',
    );

    final path = model.buildPath(params: ['electronics'], subParams: ['br']);
    expect(path, '/products/br/products/electronics');
  });

  test('static method build generates model correctly', () {
    final model = RouteModuleModel.build(
      module: 'profile',
      routeName: 'edit',
      params: ['userId'],
    );

    expect(model.name, 'edit');
    expect(model.module, '/profile');
    expect(model.params, ['userId']);
    expect(model.child, '/edit/:userId');
    expect(model.route, '/profile/edit');
  });

  test('buildPath works with child path without parameters', () {
    final model = RouteModuleModel(
      route: '/home',
      module: '/home',
      child: '/dashboard',
    );

    final result = model.buildPath(params: ['extra'], subParams: ['user']);
    expect(result, '/home/user/dashboard/extra');
  });

  test('build normalizes redundant slashes', () {
    final model = RouteModuleModel(
      route: '//a//b/',
      module: '//a//',
      child: '//b/:id/',
    );

    final result = model.buildPath(params: ['1'], subParams: []);
    expect(result, '/a/b/1');
  });

  test('build extracts correct name when routeName has trailing slash', () {
    final model = RouteModuleModel.build(
      module: 'settings',
      routeName: 'preferences/',
      params: [],
    );

    expect(model.name, 'preferences');
  });
}
