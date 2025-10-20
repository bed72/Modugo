import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/interfaces/guard_interface.dart';

void main() {
  test('AllowGuard should allow navigation (returns null)', () async {
    final guard = _AllowGuard();
    final result = await guard(_FakeBuildContext(), _FakeGoRouterState());
    expect(result, isNull);
  });

  test('RedirectGuard should redirect to /login', () async {
    final guard = _RedirectGuard();
    final result = await guard(_FakeBuildContext(), _FakeGoRouterState());
    expect(result, '/login');
  });

  test('SideEffectGuard should execute side effect and return void', () async {
    final guard = _SideEffectGuard();
    await guard(_FakeBuildContext(), _FakeGoRouterState());

    expect(guard.called, isTrue);
  });
}

final class _FakeBuildContext extends Fake implements BuildContext {}

final class _FakeGoRouterState extends Fake implements GoRouterState {}

final class _AllowGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async => null;
}

final class _RedirectGuard implements IGuard {
  @override
  Future<String?> call(BuildContext context, GoRouterState state) async =>
      '/login';
}

final class _SideEffectGuard implements IGuard {
  bool called = false;

  @override
  Future<String?> call(BuildContext context, GoRouterState state) async {
    called = true;

    return null;
  }
}
