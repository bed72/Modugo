export 'src/guard.dart';
export 'src/logger.dart';
export 'src/modugo.dart';
export 'src/transition.dart';

export 'src/modules/module.dart';
export 'src/modules/binder_module.dart';
export 'src/modules/router_module.dart';

export 'src/events/event_channel.dart';
export 'src/registers/event_registry.dart';
export 'src/mixins/after_layout_mixin.dart';
export 'src/widgets/modugo_loader_widget.dart';

export 'src/interfaces/guard_interface.dart';
export 'src/interfaces/route_interface.dart';

export 'src/models/route_model.dart';
export 'src/models/path_token_model.dart';
export 'src/models/parameter_token_model.dart';
export 'src/models/route_change_event_model.dart';

export 'src/routes/child_route.dart';
export 'src/routes/match_route.dart';
export 'src/routes/module_route.dart';
export 'src/routes/compiler_route.dart';
export 'src/routes/shell_module_route.dart';
export 'src/routes/stateful_shell_module_route.dart';

export 'src/extensions/uri_extension.dart';
export 'src/extensions/match_route_extension.dart';
export 'src/extensions/context_state_extension.dart';
export 'src/extensions/context_match_extension.dart';
export 'src/extensions/context_injection_extension.dart';
export 'src/extensions/context_navigation_extension.dart';

export 'package:get_it/get_it.dart' show GetIt;
export 'package:go_router/go_router.dart'
    show GoRouterState, StatefulNavigationShell, StatefulNavigationShellState;
