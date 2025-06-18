import 'package:flutter/widgets.dart';

import 'package:modugo/src/injector.dart';

extension ContextInjectionExtension on BuildContext {
  T read<T>() => Injector().get<T>();
}
