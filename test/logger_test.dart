import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/logger.dart';
import 'package:modugo/src/interfaces/route_interface.dart';
import 'package:modugo/src/routes/child_route.dart';

void main() {
  group('Logger - respects debugLogDiagnostics', () {
    test('should not throw when debugLogDiagnostics is false', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        debugLogDiagnostics: false,
      );

      expect(() => Logger.information('test'), returnsNormally);
      expect(() => Logger.debug('test'), returnsNormally);
      expect(() => Logger.warn('test'), returnsNormally);
      expect(() => Logger.error('test'), returnsNormally);
      expect(() => Logger.module('test'), returnsNormally);
      expect(() => Logger.injection('test'), returnsNormally);
      expect(() => Logger.dispose('test'), returnsNormally);
      expect(() => Logger.navigation('test'), returnsNormally);
    });

    test('should not throw when debugLogDiagnostics is true', () async {
      await Modugo.configure(
        module: _SimpleModule(),
        debugLogDiagnostics: true,
      );

      expect(() => Logger.information('info message'), returnsNormally);
      expect(() => Logger.debug('debug message'), returnsNormally);
      expect(() => Logger.warn('warn message'), returnsNormally);
      expect(() => Logger.error('error message'), returnsNormally);
      expect(() => Logger.module('module message'), returnsNormally);
      expect(() => Logger.injection('inject message'), returnsNormally);
      expect(() => Logger.dispose('dispose message'), returnsNormally);
      expect(() => Logger.navigation('navigation message'), returnsNormally);
    });
  });
}

final class _SimpleModule extends Module {
  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const Placeholder()),
  ];
}
