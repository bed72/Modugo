import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:modugo/src/module.dart';
import 'package:modugo/src/events/event.dart';
import 'package:modugo/src/mixins/event_mixin.dart';

/// Documents the correct cleanup order when IEvent coexists with GetIt dispose.
///
/// When a module uses IEvent and its binds have dispose callbacks, the correct
/// cleanup order is:
///
///   1. module.dispose()          — cancel event subscriptions (IEvent)
///   2. `i.unregister<T>()` / `reset` — remove binds (GetIt calls dispose callbacks)
///
/// If the order is reversed, an active event listener may try to access a
/// service that has already been unregistered from GetIt, causing a runtime error.
void main() {
  setUp(() {
    GetIt.instance.allowReassignment = true;
    Event.i.disposeAll();
  });

  tearDown(() async {
    Event.i.disposeAll();
    await GetIt.instance.reset();
    GetIt.instance.allowReassignment = false;
    Module.resetRegistrations();
  });

  group('IEvent + GetIt cleanup order', () {
    test('correct order: dispose listeners THEN unregister binds', () async {
      final operations = <String>[];

      // Register a service with dispose callback
      GetIt.instance.registerSingleton<_AnalyticsService>(
        _AnalyticsService(),
        dispose: (_) => operations.add('service_disposed'),
      );

      // Create module with event listener that uses the service
      final module = _AnalyticsModule(
        onEvent: () => operations.add('event_received'),
      );
      module.listen();

      // CORRECT ORDER:
      // 1. Cancel event subscriptions first
      module.dispose();
      operations.add('listeners_cancelled');

      // 2. Then remove the service
      GetIt.instance.unregister<_AnalyticsService>();

      expect(operations, ['listeners_cancelled', 'service_disposed']);
    });

    test(
      'global reset pattern: Event.disposeAll() before GetIt.reset()',
      () async {
        final operations = <String>[];

        GetIt.instance.registerSingleton<_AnalyticsService>(
          _AnalyticsService(),
          dispose: (_) => operations.add('service_disposed'),
        );

        final module = _AnalyticsModule(
          onEvent: () => operations.add('event_received'),
        );
        module.listen();

        // CORRECT PATTERN for global reset (e.g., logout):
        // 1. Cancel ALL event listeners
        Event.i.disposeAll();
        operations.add('all_events_cleared');

        // 2. Reset GetIt (calls all dispose callbacks)
        Module.resetRegistrations();
        await GetIt.instance.reset();

        expect(operations, ['all_events_cleared', 'service_disposed']);
      },
    );

    test('event listener does not fire after module.dispose()', () async {
      bool listenerFired = false;

      GetIt.instance.registerSingleton<_AnalyticsService>(_AnalyticsService());

      final module = _AnalyticsModule(onEvent: () => listenerFired = true);
      module.listen();

      // Dispose listeners
      module.dispose();

      // Emit event — listener should NOT fire
      Event.emit(_TrackEvent('test'));
      await Future<void>.delayed(Duration.zero);

      expect(listenerFired, isFalse);
    });
  });
}

class _AnalyticsService {}

class _TrackEvent {
  final String name;
  _TrackEvent(this.name);
}

final class _AnalyticsModule extends Module with IEvent {
  final void Function() onEvent;

  _AnalyticsModule({required this.onEvent});

  @override
  void listen() {
    on<_TrackEvent>((_) => onEvent());
  }
}
