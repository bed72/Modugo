import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:modugo/src/logger.dart';
import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/transition.dart';

import 'package:modugo/src/interfaces/route_interface.dart';

import 'package:modugo/src/routes/alias_route.dart';
import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/routes/module_route.dart';
import 'package:modugo/src/routes/compiler_route.dart';
import 'package:modugo/src/routes/shell_module_route.dart';
import 'package:modugo/src/decorators/guard_module_decorator.dart';
import 'package:modugo/src/routes/stateful_shell_module_route.dart';

/// A centralized factory responsible for building GoRouter-compatible [RouteBase] objects
/// from Modugo's declarative [IRoute] definitions.
///
/// The [FactoryRoute] acts as the bridge between Modugo’s modular route layer and
/// Flutter’s native navigation system ([GoRouter]). It converts high-level route
/// declarations such as [ChildRoute], [ModuleRoute], [AliasRoute], [ShellModuleRoute],
/// and [StatefulShellModuleRoute] into valid [GoRoute] and [ShellRoute] configurations.
///
/// ### 🧩 Responsibilities
/// - Compiles and validates all modular routes before building the router.
/// - Applies guards, redirects, and transition animations automatically.
/// - Handles nested module composition and alias mapping seamlessly.
/// - Ensures consistency and safety across all route types using [_safe] and [_safeAsync].
///
/// ### 🛠️ How It Works
/// Each type of [IRoute] is transformed using a dedicated builder:
/// - [_createChild] → Builds a single [GoRoute] from a [ChildRoute].
/// - [_createAlias] → Creates an alias that redirects to another [ChildRoute].
/// - [_createModule] → Builds a [GoRoute] that represents an entire [Module].
/// - [_createShell] → Composes a modular [ShellRoute] for persistent UIs (e.g., bottom bars).
/// - [_createStatefulShell] → Builds a [StatefulShellRoute] for branch-based navigation.
///
/// The resulting [RouteBase] objects are combined into a single list for GoRouter.
///
/// ### 🧠 Safety & Error Handling
/// - All route builders are wrapped in [_safe] or [_safeAsync], ensuring consistent
///   error logging via [Logger.error] without losing stack traces.
/// - Paths are validated with [_validatePath] using [CompilerRoute], guaranteeing
///   syntactic integrity of route patterns.
/// - When route definitions are invalid or unsupported, the factory throws descriptive
///   exceptions ([ArgumentError], [StateError], or [UnsupportedError]).
///
/// ### 🧭 Example
/// ```dart
/// final routes = RoutesFactory.from([
///   ChildRoute(path: '/home', child: (_, _) => const HomePage()),
///   ModuleRoute(path: '/auth', module: AuthModule()),
///   ShellModuleRoute(
///     builder: (_, _, child) => Scaffold(body: child),
///     routes: [
///       ChildRoute(path: '/a', child: (_, _) => const APage()),
///       ChildRoute(path: '/b', child: (_, _) => const BPage()),
///     ],
///   ),
/// ]);
///
/// final router = GoRouter(routes: routes);
/// ```
///
/// ### ⚠️ Notes
/// - [ModuleRoute] instances must define at least one [ChildRoute].
/// - Aliases must point to an existing [ChildRoute] within the same context.
/// - Guards and redirects are executed in order; returning `null` continues navigation.
///
/// In short, this class guarantees that every route defined in Modugo’s modular
/// structure is validated, guarded, and ready for use within Flutter’s [GoRouter].
final class FactoryRoute {
  const FactoryRoute._();

  /// Converts a list of Modugo [IRoute] definitions into a flattened list of
  /// GoRouter-compatible [RouteBase] objects.
  ///
  /// This is the main entry point of the [FactoryRoute]. It scans each provided
  /// modular route and delegates the creation process to the correct specialized
  /// builder based on the route type.
  ///
  /// ### 🧩 Responsibilities
  /// - Iterates through all [IRoute] instances declared in a [Module].
  /// - Detects the route subtype and calls its corresponding internal builder:
  ///   - [_createChild] → for [ChildRoute] instances.
  ///   - [_createAlias] → for [AliasRoute] instances.
  ///   - [_createModule] → for [ModuleRoute] instances.
  ///   - [_createShell] → for [ShellModuleRoute] containers.
  ///   - [_createStatefulShell] → for [StatefulShellModuleRoute] branches.
  /// - Collects and merges the generated [RouteBase]s into a single ordered list.
  ///
  /// ### 🧠 Return Order
  /// The method enforces a specific ordering to maintain navigation consistency:
  /// 1. **Shell routes** ([ShellModuleRoute], [StatefulShellModuleRoute])
  ///    — define structural UI layers or persistent navigation containers.
  /// 2. **Child routes** ([ChildRoute], [AliasRoute])
  ///    — represent concrete leaf pages.
  /// 3. **Module routes** ([ModuleRoute])
  ///    — represent nested modular route groups.
  ///
  /// This ensures that shell-based layouts are registered before leaf or module routes,
  /// preserving the correct parent-child navigation hierarchy in [GoRouter].
  ///
  /// ### ⚠️ Error Handling
  /// Throws an [UnsupportedError] if the provided [IRoute] type is not recognized
  /// or supported by the factory.
  ///
  /// ### 🧭 Example
  /// ```dart
  /// final routes = RoutesFactory.from([
  ///   ChildRoute(path: '/home', child: (_, _) => const HomePage()),
  ///   ModuleRoute(path: '/auth', module: AuthModule()),
  ///   ShellModuleRoute(
  ///     builder: (_, _, child) => AppShell(child: child),
  ///     routes: [
  ///       ChildRoute(path: '/feed', child: (_, _) => const FeedPage()),
  ///     ],
  ///   ),
  /// ]);
  ///
  /// final router = GoRouter(routes: routes);
  /// ```
  ///
  /// Returns:
  /// A single, flattened [List] of [RouteBase] objects ready for
  /// consumption by [GoRouter].
  static List<RouteBase> from(List<IRoute> routes) {
    final childs = <GoRoute>[];
    final modules = <GoRoute>[];
    final shells = <RouteBase>[];

    for (final route in routes) {
      switch (route) {
        case ChildRoute():
          childs.add(_createChild(route));

        case AliasRoute():
          childs.add(_createAlias(route, routes));

        case ModuleRoute():
          modules.add(_createModule(route));

        case ShellModuleRoute():
          shells.add(_createShell(route));

        case StatefulShellModuleRoute():
          shells.add(_createStatefulShell(route));

        case _:
          throw UnsupportedError(
            'Unsupported route type: ${route.runtimeType}',
          );
      }
    }

    return [...shells, ...childs, ...modules];
  }

  static GoRoute _createChild(ChildRoute route) {
    _validatePath(route.path, 'ChildRoute');

    return GoRoute(
      path: route.path,
      name: route.name,
      parentNavigatorKey: route.parentNavigatorKey,
      redirect: (context, state) async {
        for (final guard in route.guards) {
          final safety = await guard(context, state);
          if (safety != null) return safety;
        }

        return null;
      },
      pageBuilder:
          (context, state) =>
              route.pageBuilder != null
                  ? route.pageBuilder!(context, state)
                  : _transition(context: context, state: state, route: route),
    );
  }

  static GoRoute _createAlias(AliasRoute alias, List<IRoute> routes) {
    final route = routes.whereType<ChildRoute>().firstWhere(
      (child) => child.path == alias.to,
      orElse:
          () =>
              throw ArgumentError(
                'Alias "${alias.from}" points to "${alias.to}", but no matching ChildRoute was found.',
              ),
    );

    _validatePath(alias.from, 'AliasRoute');

    return GoRoute(
      path: alias.from,
      redirect: (context, state) async {
        for (final guard in route.guards) {
          final safety = await guard(context, state);
          if (safety != null) return safety;
        }

        return null;
      },
      pageBuilder:
          (context, state) =>
              route.pageBuilder != null
                  ? route.pageBuilder!(context, state)
                  : _transition(context: context, state: state, route: route),
    );
  }

  static GoRoute _createModule(ModuleRoute route) {
    final module = route.module;
    final first = module.routes().whereType<ChildRoute>().firstOrNull;

    if (first == null) {
      throw StateError(
        'ModuleRoute "${route.name ?? module.runtimeType}" '
        'must contain at least one ChildRoute.',
      );
    }

    _validatePath(first.path, 'ModuleRoute');

    return GoRoute(
      path: route.path,
      name: route.name,
      routes: module.configureRoutes(),
      parentNavigatorKey: route.parentNavigatorKey ?? first.parentNavigatorKey,
      redirect: (context, state) async {
        if (module is GuardModuleDecorator) {
          for (final guard in module.guards) {
            final safety = await guard(context, state);
            if (safety != null) return safety;
          }
        }

        return null;
      },
      pageBuilder: (context, state) {
        try {
          final widget = first.child(context, state);

          return _transition(context: context, state: state, widget: widget);
        } catch (exception, stack) {
          Logger.error(
            'Error building ModuleRoute (${route.path}): $exception\n$stack',
          );

          rethrow;
        }
      },
    );
  }

  static ShellRoute _createShell(ShellModuleRoute route) {
    final routes =
        route.routes
            .map((iRoute) {
              if (iRoute is ChildRoute) return _createChild(iRoute);
              if (iRoute is ModuleRoute) return _createModule(iRoute);
              return null;
            })
            .whereType<RouteBase>()
            .toList();

    return ShellRoute(
      routes: routes,
      observers: route.observers,
      navigatorKey: route.navigatorKey,
      parentNavigatorKey: route.parentNavigatorKey,
      builder: (context, state, child) {
        try {
          return route.builder!(context, state, child);
        } catch (exception, stack) {
          Logger.error('Error building ShellModuleRoute: $exception\n$stack');
          rethrow;
        }
      },
      pageBuilder:
          route.pageBuilder == null
              ? null
              : (context, state, child) =>
                  route.pageBuilder!(context, state, child),
    );
  }

  static StatefulShellRoute _createStatefulShell(
    StatefulShellModuleRoute route,
  ) {
    final branches =
        route.routes.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          if (child is ModuleRoute) {
            final module = child.module.configureRoutes();

            final routes =
                module.map((route) {
                  if (route is! GoRoute) return route;

                  final composed = _normalizeComposedPath(
                    child.path,
                    route.path,
                  );
                  _validatePath(composed, 'StatefulShellModuleRoute');

                  return GoRoute(
                    path: composed,
                    name: route.name,
                    routes: route.routes,
                    redirect: route.redirect,
                    pageBuilder: route.pageBuilder,
                    parentNavigatorKey:
                        route.parentNavigatorKey ?? child.parentNavigatorKey,
                  );
                }).toList();

            return StatefulShellBranch(
              routes: routes,
              navigatorKey: child.parentNavigatorKey,
            );
          }

          if (child is ChildRoute) {
            final path = child.path.isEmpty ? '/' : child.path;
            _validatePath(path, 'StatefulShellModuleRoute');

            return StatefulShellBranch(
              routes: [
                _createChild(
                  ChildRoute(
                    path: path,
                    child: child.child,
                    guards: child.guards,
                    transition: child.transition,
                    pageBuilder: child.pageBuilder,
                    name: child.name ?? 'branch_$index',
                    parentNavigatorKey: child.parentNavigatorKey,
                  ),
                ),
              ],
            );
          }

          throw UnsupportedError(
            'Unsupported route type inside StatefulShellModuleRoute: ${child.runtimeType}',
          );
        }).toList();

    return StatefulShellRoute.indexedStack(
      key: route.key,
      branches: branches,
      parentNavigatorKey: route.parentNavigatorKey,
      pageBuilder: (context, state, shell) {
        try {
          final widget = route.builder(context, state, shell);
          return _transition(context: context, state: state, widget: widget);
        } catch (exception, stack) {
          Logger.error(
            'Error building StatefulShellModuleRoute (${route.runtimeType}): $exception\n$stack',
          );
          rethrow;
        }
      },
    );
  }

  static void _validatePath(String path, String type) {
    try {
      final compiler = CompilerRoute(path);
      Logger.navigation('[$type] Valid path: ${compiler.pattern}');
    } catch (exception) {
      Logger.error('Invalid path in $type: $path → $exception');
      throw ArgumentError.value(
        path,
        'path',
        'Invalid syntax in $type: $exception',
      );
    }
  }

  static String _normalizeComposedPath(String parent, String child) {
    if (parent == '/' || parent.isEmpty) {
      if (child.isEmpty) return '/';
      return child.startsWith('/') ? child : '/$child';
    }

    final prefix =
        parent.endsWith('/') ? parent.substring(0, parent.length - 1) : parent;

    if (child == '/' || child.isEmpty) return prefix;

    final subpath = child.startsWith('/') ? child : '/$child';
    return '$prefix$subpath';
  }

  static Page<void> _transition({
    required BuildContext context,
    required GoRouterState state,
    Widget? widget,
    ChildRoute? route,
  }) {
    final child = widget ?? route?.child(context, state);

    if (child == null) {
      final name = route?.name ?? 'UnknownRoute';
      final path = route?.path ?? state.uri.toString();
      final message = '''
        [RoutesFactory] Failed to build transition page.
        Path: "$path"
        Route: "$name"
        Both the provided [widget] and [route.child] returned null.
        Ensure that the route defines a valid builder or child widget.
      ''';

      Logger.error(message);
      throw StateError(message);
    }

    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: Transition.builder(
        config: () {},
        type: route?.transition ?? Modugo.getDefaultTransition,
      ),
    );
  }
}
