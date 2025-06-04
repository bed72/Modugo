import 'package:flutter/widgets.dart';
import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';

class ModugoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final name = _routeName(route);
    ModugoLogger.info('🔼 PUSH → $name');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final name = _routeName(route);
    ModugoLogger.info('🔽 POP ← $name');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (!Modugo.debugLogDiagnostics) return;

    final from = _routeName(oldRoute);
    final to = _routeName(newRoute);
    ModugoLogger.info('🔁 REPLACE: $from → $to');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final name = _routeName(route);
    ModugoLogger.warn('🗑️ REMOVE → $name');
  }

  String _routeName(Route? route) {
    if (route == null) return 'null';

    final settings = route.settings;
    if (settings.name != null) return settings.name!;
    if (settings is Page) return settings.runtimeType.toString();

    return settings.toString();
  }
}
