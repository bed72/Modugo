// coverage:ignore-file

import 'package:flutter/widgets.dart';

import 'package:modugo/src/modugo.dart';

import 'package:modugo/src/routes/events/route_action_event.dart';
import 'package:modugo/src/routes/events/route_change_event.dart';

/// A [NavigatorObserver] that updates [Modugo.routeNotifier]
/// with detailed [RouteChangeEvent] whenever a navigation event occurs.
///
/// This observer is injected automatically into GoRouter through [Modugo.configure],
/// and ensures that [Modugo.routeNotifier.value] always reflects:
/// - the current path
/// - the previous path
/// - the type of navigation: push, pop, or replace
///
/// This enables reactive behaviors like refreshing dynamic UI,
/// analytics tracking, or handling WebView state.
final class RouteTrackingObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _notify(
      current: route,
      previous: previousRoute,
      action: RouteActionEvent.push,
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _notify(
      previous: route,
      current: previousRoute,
      action: RouteActionEvent.pop,
    );
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _notify(
      current: newRoute,
      previous: oldRoute,
      action: RouteActionEvent.replace,
    );
  }

  void _notify({
    required RouteActionEvent action,
    Route? current,
    Route? previous,
  }) {
    final currentPath = current?.settings.name;
    final previousPath = previous?.settings.name;

    if (currentPath != null && previousPath != null) {
      Modugo.routeNotifier.update(
        RouteChangeEvent(
          action: action,
          current: currentPath,
          previous: previousPath,
        ),
      );
    }
  }
}
