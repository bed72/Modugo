import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/extensions/go_router_state_extension.dart';

void main() {
  group('GoRouterStateExtension.getExtra — safe cast (DESIGN-9 fixed)', () {
    test('getExtra returns value when types match', () {
      final state = _ExtraState('hello');
      expect(state.getExtra<String>(), 'hello');
    });

    test('getExtra returns null when extra is null', () {
      final state = _ExtraState(null);
      expect(state.getExtra<String>(), isNull);
    });

    test(
      'getExtra returns null when extra has wrong type (DESIGN-9 fixed)',
      () {
        // Previously threw TypeError. Now returns null safely.
        final state = _ExtraState(42);
        expect(state.getExtra<String>(), isNull);
      },
    );

    test('getExtra returns null for int when String is requested', () {
      expect(_ExtraState(42).getExtra<String>(), isNull);
    });

    test('getExtra returns value when int is requested and extra is int', () {
      expect(_ExtraState(42).getExtra<int>(), 42);
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
