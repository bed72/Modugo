// coverage:ignore-file

import 'package:modugo/src/injector.dart';

abstract interface class IBind<T> {
  T get(Injector injector);
  void dispose();
}
