import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/go_router_state_extension.dart';

/// Documents DESIGN-9:
/// `getExtra<T>()` uses an unsafe cast (`extra as T?`). When `extra` is a
/// non-null value of the wrong type, a `CastError` / `TypeError` is thrown
/// instead of returning null as the doc comment implies.
///
/// When DESIGN-9 is fixed (safe cast: `extra is T ? extra as T : null`),
/// the "wrong type throws" test should be updated to assert the result is null.
void main() {
  group('GoRouterStateExtension.getExtra — DESIGN-9 unsafe cast', () {
    test('getExtra returns correct type when types match', () {
      final state = _ExtraState('hello');
      expect(state.getExtra<String>(), 'hello');
    });

    test('getExtra returns null when extra is null', () {
      final state = _ExtraState(null);
      expect(state.getExtra<String>(), isNull);
    });

    test('[DESIGN-9] getExtra throws TypeError when extra has wrong type', () {
      // extra is an int, but we request String.
      // With a safe cast this should return null; currently it throws.
      final state = _ExtraState(42);
      expect(
        () => state.getExtra<String>(),
        throwsA(isA<TypeError>()),
        reason: 'DESIGN-9: unsafe cast throws instead of returning null',
      );
    });
  });
}

final class _ExtraState extends Fake implements GoRouterState {
  _ExtraState(this._extra);

  final Object? _extra;

  @override
  Object? get extra => _extra;

  @override
  Uri get uri => Uri.parse('/');

  @override
  String? get name => null;

  @override
  String get matchedLocation => '/';

  @override
  Map<String, String> get pathParameters => const {};
}
