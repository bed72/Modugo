// coverage:ignore-file

import 'dart:async';

import 'package:modugo/src/injectors/async_injector.dart';
import 'package:modugo/src/injectors/sync_injector.dart';

base class Injector {
  T getSync<T>() => SyncBind.get<T>();
  Future<T> getAsync<T>() => AsyncBind.get<T>();
}
