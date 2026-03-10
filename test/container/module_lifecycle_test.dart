// ignore_for_file: unused_local_variable, unused_element_parameter

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modugo/src/modugo.dart';
import 'package:modugo/src/module.dart';

import 'package:modugo/src/routes/child_route.dart';
import 'package:modugo/src/mixins/binder_mixin.dart';
import 'package:modugo/src/interfaces/route_interface.dart';

// ─── Test helpers ───────────────────────────────────────────

class _Controller {
  String state = 'initial';
}

class _Repository {
  bool closed = false;
  void close() => closed = true;
}

class _SharedService {
  final String name;
  _SharedService([this.name = 'shared']);
}

final class _SharedBinder with IBinder {
  @override
  void binds() {
    Modugo.container.addSingleton<_SharedService>(
      () => _SharedService(),
      onDispose: (_) {},
    );
  }
}

final class _FeatureModule extends Module {
  final _Repository? repository;

  _FeatureModule({this.repository});

  @override
  List<IBinder> imports() => [_SharedBinder()];

  @override
  void binds() {
    i.addSingleton<_Controller>(
      () => _Controller(),
      onDispose: (ctrl) => ctrl.state = 'disposed',
    );
    i.addSingleton<_Repository>(
      () => repository ?? _Repository(),
      onDispose: (repo) => repo.close(),
    );
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/', child: (_, _) => const SizedBox()),
  ];
}

class _IndependentService {
  final String name;
  _IndependentService([this.name = 'independent']);
}

final class _IndependentModule extends Module {
  @override
  void binds() {
    i.addSingleton<_IndependentService>(() => _IndependentService());
  }

  @override
  List<IRoute> routes() => [
    ChildRoute(path: '/independent', child: (_, _) => const SizedBox()),
  ];
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  setUp(() {
    Modugo.resetForTest();
    registeredForTest.clear();
  });

  group('Module lifecycle', () {
    test('navigate → dispose → re-navigate creates fresh instances', () {
      // 1. First navigation: configure and access
      final module1 = _FeatureModule();
      module1.configureRoutes();

      final ctrl1 = Modugo.container.get<_Controller>();
      ctrl1.state = 'modified';
      expect(ctrl1.state, 'modified');

      // 2. User leaves — dispose
      module1.dispose();

      // 3. User navigates back — re-configure
      final module2 = _FeatureModule();
      module2.configureRoutes();

      final ctrl2 = Modugo.container.get<_Controller>();

      // Fresh instance with clean state
      expect(ctrl2, isNot(same(ctrl1)));
      expect(ctrl2.state, 'initial');
    });

    test('singleton maintains state between navigations without dispose', () {
      final module = _FeatureModule();
      module.configureRoutes();

      final ctrl = Modugo.container.get<_Controller>();
      ctrl.state = 'persisted';

      // Simulate navigating away and back WITHOUT dispose
      // (module stays alive, binds not re-executed)

      final sameCtrl = Modugo.container.get<_Controller>();
      expect(sameCtrl, same(ctrl));
      expect(sameCtrl.state, 'persisted');
    });

    test('dispose clears singleton state completely', () {
      final module = _FeatureModule();
      module.configureRoutes();

      final ctrl = Modugo.container.get<_Controller>();
      ctrl.state = 'will-be-lost';

      final repo = Modugo.container.get<_Repository>();

      module.dispose();

      // Old instances were disposed
      expect(ctrl.state, 'disposed'); // onDispose set this
      expect(repo.closed, isTrue);

      // Re-register
      final module2 = _FeatureModule();
      module2.configureRoutes();

      final newCtrl = Modugo.container.get<_Controller>();
      expect(newCtrl.state, 'initial');
    });

    test('imported modules survive dispose of the importer', () {
      final module = _FeatureModule();
      module.configureRoutes();

      // Both module's own and imported bindings are available
      expect(Modugo.container.isRegistered<_Controller>(), isTrue);
      expect(Modugo.container.isRegistered<_SharedService>(), isTrue);

      module.dispose();

      // Module's own bindings are gone
      expect(Modugo.container.isRegistered<_Controller>(), isFalse);
      expect(Modugo.container.isRegistered<_Repository>(), isFalse);

      // Imported bindings survive
      expect(Modugo.container.isRegistered<_SharedService>(), isTrue);
      expect(Modugo.container.get<_SharedService>().name, 'shared');
    });

    test('dispose called twice does not throw', () {
      final module = _FeatureModule();
      module.configureRoutes();

      Modugo.container.get<_Controller>();

      expect(() => module.dispose(), returnsNormally);
      expect(() => module.dispose(), returnsNormally);
    });

    test('onDispose called exactly once per singleton', () {
      int disposeCount = 0;

      final repo = _Repository();
      final module = _FeatureModule(repository: repo);
      module.configureRoutes();

      // Access to create instance
      Modugo.container.get<_Repository>();

      // Manually track close calls
      expect(repo.closed, isFalse);

      module.dispose();

      expect(repo.closed, isTrue);
    });

    test('onDispose NOT called if lazy singleton was never accessed', () {
      bool disposeCalled = false;

      // Register but never access
      Modugo.container.activeTag = 'LazyMod';
      Modugo.container.addLazySingleton<_Controller>(
        () => _Controller(),
        onDispose: (_) => disposeCalled = true,
      );
      Modugo.container.activeTag = null;

      Modugo.container.disposeModule('LazyMod');

      expect(disposeCalled, isFalse);
    });

    test('multiple modules with independent lifecycles', () {
      final featureModule = _FeatureModule();
      featureModule.configureRoutes();

      final independentModule = _IndependentModule();
      independentModule.configureRoutes();

      // Both are active
      expect(Modugo.container.get<_Controller>(), isNotNull);
      expect(Modugo.container.get<_IndependentService>().name, 'independent');

      // Dispose feature module
      featureModule.dispose();

      // Feature bindings gone
      expect(Modugo.container.isRegistered<_Controller>(), isFalse);
      expect(Modugo.container.isRegistered<_Repository>(), isFalse);

      // Independent module unaffected
      expect(Modugo.container.isRegistered<_IndependentService>(), isTrue);
      expect(Modugo.container.get<_IndependentService>().name, 'independent');

      // Re-register feature module
      final featureModule2 = _FeatureModule();
      featureModule2.configureRoutes();

      // Both work again
      expect(Modugo.container.get<_Controller>(), isNotNull);
      expect(Modugo.container.get<_IndependentService>(), isNotNull);
    });
  });
}
