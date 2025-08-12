export 'src/guard.dart';
export 'src/logger.dart';
export 'src/modugo.dart';
export 'src/module.dart';
export 'src/dispose.dart';
export 'src/manager.dart';
export 'src/injector.dart';
export 'src/binding_key.dart';
export 'src/transition.dart';

export 'src/notifiers/router_notifier.dart';

export 'src/binds/factory_bind.dart';
export 'src/binds/singleton_bind.dart';
export 'src/binds/lazy_singleton_bind.dart';

export 'src/interfaces/bind_interface.dart';
export 'src/interfaces/guard_interface.dart';
export 'src/interfaces/module_interface.dart';
export 'src/interfaces/manager_interface.dart';
export 'src/interfaces/injector_interface.dart';

export 'src/routes/child_route.dart';
export 'src/routes/match_route.dart';
export 'src/routes/module_route.dart';
export 'src/routes/compiler_route.dart';
export 'src/routes/shell_module_route.dart';
export 'src/routes/stateful_shell_module_route.dart';

export 'src/routes/models/route_model.dart';
export 'src/routes/models/path_token_model.dart';
export 'src/routes/models/route_pattern_model.dart';
export 'src/routes/models/parameter_token_model.dart';

export 'src/extensions/match_route_extension.dart';
export 'src/extensions/context_state_extension.dart';
export 'src/extensions/context_match_extension.dart';
export 'src/extensions/context_injection_extension.dart';
export 'src/extensions/context_navigation_extension.dart';

export 'package:go_router/go_router.dart'
    show GoRouterState, StatefulNavigationShell, StatefulNavigationShellState;
