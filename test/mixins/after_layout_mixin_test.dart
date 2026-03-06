import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/mixins/after_layout_mixin.dart';

void main() {
  group('AfterLayoutMixin', () {
    testWidgets('should call afterFirstLayout after first layout', (
      tester,
    ) async {
      var called = false;

      await tester.pumpWidget(_TestWidget(onAfterLayout: (_) => called = true));

      expect(called, isTrue);
    });

    testWidgets('should call afterFirstLayout exactly once', (tester) async {
      var callCount = 0;

      await tester.pumpWidget(_TestWidget(onAfterLayout: (_) => callCount++));

      await tester.pump();
      expect(callCount, 1);

      await tester.pump();
      await tester.pump();
      expect(callCount, 1);
    });

    testWidgets('should provide a valid BuildContext', (tester) async {
      BuildContext? receivedContext;

      await tester.pumpWidget(
        _TestWidget(onAfterLayout: (ctx) => receivedContext = ctx),
      );

      await tester.pump();
      expect(receivedContext, isNotNull);
    });
  });
}

final class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.onAfterLayout});

  final void Function(BuildContext context) onAfterLayout;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

final class _TestWidgetState extends State<_TestWidget> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  void afterFirstLayout(BuildContext context) {
    widget.onAfterLayout(context);
  }
}
