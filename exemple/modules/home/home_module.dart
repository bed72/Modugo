import 'package:modugo/modugo.dart';

import 'domain/repositories/repository.dart';

import 'data/repositories/repository_impl.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/controllers/home_controller.dart';

final class HomeModule extends Module {
  @override
  List<void Function(IInjector)> get binds => [
    (i) =>
        i
          ..addLazySingleton<ModugoRepository>((_) => ModugoRepositoryImpl())
          ..addSingleton<HomeController>(
            (i) => HomeController(i.get<ModugoRepository>()),
          )
          ..addFactory<DateTime>((_) => DateTime.now()),
  ];

  @override
  List<IModule> get routes => [
    ChildRoute(
      '/home',
      name: 'home-route',
      child: (context, _) {
        final controller = context.read<HomeController>();
        return HomeScreen(controller: controller);
      },
    ),
  ];
}
