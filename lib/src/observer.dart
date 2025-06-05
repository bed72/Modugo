// coverage:ignore-file

import 'package:flutter/widgets.dart';
import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';

class ModugoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final to = _routeName(route);
    final from = _routeName(previousRoute);
    ModugoLogger.navigation('🔼 PUSH: $from → $to');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final from = _routeName(route);
    final to = _routeName(previousRoute);
    ModugoLogger.navigation('🔽 POP: $from ← $to');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (!Modugo.debugLogDiagnostics) return;

    final to = _routeName(newRoute);
    final from = _routeName(oldRoute);
    ModugoLogger.navigation('🔁 REPLACE: $from → $to');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (!Modugo.debugLogDiagnostics) return;

    final name = _routeName(route);
    ModugoLogger.navigation('🗑️ REMOVE: $name');
  }

  String _routeName(Route? route) {
    if (route == null) return 'null';

    final settings = route.settings;
    if (settings.name != null) return settings.name!;
    if (settings is Page) return settings.runtimeType.toString();

    return settings.toString();
  }
}
