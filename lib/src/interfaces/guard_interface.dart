import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract interface class IGuard {
  /// Checks if the guard allows navigation to the specified route.
  ///
  /// Returns `true` if navigation is allowed, `false` otherwise.
  FutureOr<String?> canActivate(BuildContext context, GoRouterState state);
}
