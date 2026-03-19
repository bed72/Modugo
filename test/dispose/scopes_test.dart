import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Documents the GetIt scopes pattern for grouping dependencies.
///
/// Scopes are hierarchical (stack-based). Registrations in a child scope
/// shadow registrations in parent scopes. When a scope is popped, all
/// its registrations are removed and their dispose callbacks are called.
///
/// Use cases:
/// - Feature modules with temporary dependencies
/// - User session scopes (login/logout)
/// - Test isolation
void main() {
  late GetIt i;

  setUp(() {
    i = GetIt.asNewInstance();
  });

  tearDown(() async {
    await i.reset();
  });

  group('pushNewScope / popScope with dispose', () {
    test(
      'popScope removes registrations and calls dispose callbacks',
      () async {
        bool disposed = false;

        i.pushNewScope(scopeName: 'feature');
        i.registerSingleton<_Service>(
          _Service(),
          dispose: (_) => disposed = true,
        );

        expect(i.isRegistered<_Service>(), isTrue);

        await i.popScope();

        expect(disposed, isTrue);
        expect(i.isRegistered<_Service>(), isFalse);
      },
    );

    test('child scope shadows parent registration', () {
      final parentService = _NamedService('parent');
      final childService = _NamedService('child');

      i.registerSingleton<_NamedService>(parentService);

      expect(i.get<_NamedService>().name, 'parent');

      i.pushNewScope(scopeName: 'child');
      i.registerSingleton<_NamedService>(childService);

      // Child scope shadows parent
      expect(i.get<_NamedService>().name, 'child');
    });

    test('popScope restores parent scope registration', () async {
      final parentService = _NamedService('parent');
      final childService = _NamedService('child');

      i.registerSingleton<_NamedService>(parentService);

      i.pushNewScope(scopeName: 'child');
      i.registerSingleton<_NamedService>(childService);

      expect(i.get<_NamedService>().name, 'child');

      await i.popScope();

      // Parent registration is restored
      expect(i.get<_NamedService>().name, 'parent');
    });
  });

  group('named scopes', () {
    test('dropScope removes a specific named scope', () async {
      bool scopeDisposed = false;

      i.pushNewScope(scopeName: 'temporary');
      i.registerSingleton<_Service>(
        _Service(),
        dispose: (_) => scopeDisposed = true,
      );

      await i.dropScope('temporary');

      expect(scopeDisposed, isTrue);
      expect(i.isRegistered<_Service>(), isFalse);
    });

    test('hasScope checks if a named scope exists', () {
      expect(i.hasScope('feature'), isFalse);

      i.pushNewScope(scopeName: 'feature');

      expect(i.hasScope('feature'), isTrue);
    });
  });

  group('scope with init function', () {
    test('init function registers dependencies atomically', () {
      i.pushNewScope(
        scopeName: 'session',
        init: (getIt) {
          getIt.registerSingleton<_Service>(_Service());
          getIt.registerSingleton<_NamedService>(_NamedService('session'));
        },
      );

      expect(i.isRegistered<_Service>(), isTrue);
      expect(i.get<_NamedService>().name, 'session');
    });
  });
}

class _Service {}

class _NamedService {
  final String name;
  _NamedService(this.name);
}
