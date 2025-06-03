final class SyncServiceMock {
  int value = 0;
}

final class SyncOtherServiceMock {
  final int id;
  SyncOtherServiceMock({this.id = 0});
}

final class AsyncServiceMock {
  final void Function() onClose;
  AsyncServiceMock({required this.onClose});
  void close() => onClose();
}

final class AsyncOtherServiceMock {
  final void Function() onClose;
  AsyncOtherServiceMock({required this.onClose});
  void close() => onClose();
}
