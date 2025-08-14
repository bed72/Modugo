import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/events/event_channel.dart';

void main() {
  late EventBus eventBus;

  setUp(() {
    eventBus = EventBus();
    EventChannel.instance.disposeAll(eventBus: eventBus);
  });

  test('EventChannel singleton works correctly', () {
    final first = EventChannel.instance;
    final second = EventChannel.instance;
    expect(identical(first, second), isTrue);
  });

  test('Registers and receives event via default EventBus', () async {
    String received = '';
    EventChannel.instance.on<_EventMock>((event) {
      received = event.message;
    });

    EventChannel.emit(_EventMock('Hello'));
    await Future.delayed(Duration.zero);
    expect(received, 'Hello');
  });

  test('Registers and receives event via custom EventBus', () async {
    String received = '';
    EventChannel.instance.on<_EventMock>((event) {
      received = event.message;
    }, eventBus: eventBus);

    eventBus.fire(_EventMock('CustomBus'));
    await Future.delayed(Duration.zero);
    expect(received, 'CustomBus');
  });

  test('Dispose specific listener stops receiving events', () async {
    String received = '';
    EventChannel.instance.on<_EventMock>((event) {
      received = event.message;
    }, eventBus: eventBus);

    EventChannel.instance.dispose<_EventMock>(eventBus: eventBus);

    eventBus.fire(_EventMock('Should not receive'));
    await Future.delayed(Duration.zero);
    expect(received, '');
  });

  test('Dispose all listeners stops receiving events', () async {
    String received = '';
    EventChannel.instance.on<_EventMock>((event) {
      received = event.message;
    }, eventBus: eventBus);

    EventChannel.instance.disposeAll(eventBus: eventBus);

    eventBus.fire(_EventMock('Should not receive'));
    await Future.delayed(Duration.zero);
    expect(received, '');
  });

  test('Broadcast listeners receive multiple events', () async {
    List<String> messages = <String>[];
    EventChannel.instance.on<_EventMock>(
      (event) {
        messages.add(event.message);
      },
      eventBus: eventBus,
      broadcast: true,
    );

    eventBus.fire(_EventMock('A'));
    eventBus.fire(_EventMock('B'));
    await Future.delayed(Duration.zero);

    expect(messages, ['A', 'B']);
  });
}

final class _EventMock {
  final String message;
  _EventMock(this.message);
}
