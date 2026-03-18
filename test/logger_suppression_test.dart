import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/logger.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/routes/child_route.dart';

void main() {
  tearDown(() {
    Modugo.resetForTesting();
    GetIt.instance.reset();
  });

  group('Logger suppression via debugLogDiagnostics', () {
    test('debugLogDiagnostics is false by default', () async {
      await Modugo.configure(module: _SimpleModule());
      expect(Modugo.debugLogDiagnostics, isFalse);
    });

    test(
      'all Logger methods return normally when suppressed (flag=false)',
      () async {
        await Modugo.configure(
          module: _SimpleModule(),
          debugLogDiagnostics: false,
        );

        expect(Modugo.debugLogDiagnostics, isFalse);

        // None of these should throw — and since the flag is false they are no-ops.
        expect(() => Logger.information('x'), returnsNormally);
        expect(() => Logger.debug('x'), returnsNormally);
        expect(() => Logger.warn('x'), returnsNormally);
        expect(() => Logger.error('x'), returnsNormally);
        expect(() => Logger.module('x'), returnsNormally);
        expect(() => Logger.injection('x'), returnsNormally);
        expect(() => Logger.dispose('x'), returnsNormally);
        expect(() => Logger.navigation('x'), returnsNormally);
      },
    );

    test(
      'all Logger methods return normally when enabled (flag=true)',
      () async {
        await Modugo.configure(
          module: _SimpleModule(),
          debugLogDiagnostics: true,
        );

        expect(Modugo.debugLogDiagnostics, isTrue);

        expect(() => Logger.information('info'), returnsNormally);
        expect(() => Logger.debug('debug'), returnsNormally);
        expect(() => Logger.warn('warn'), returnsNormally);
        expect(() => Logger.error('error'), returnsNormally);
        expect(() => Logger.module('module'), returnsNormally);
        expect(() => Logger.injection('inject'), returnsNormally);
        expect(() => Logger.dispose('dispose'), returnsNormally);
        expect(() => Logger.navigation('nav'), returnsNormally);
      },
    );

    test('debugLogDiagnostics true is stored correctly', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        debugLogDiagnostics: true,
      );
      expect(Modugo.debugLogDiagnostics, isTrue);
    });
  });
}

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}
