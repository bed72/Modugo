import 'package:modugo/modugo.dart';

import 'modules/home/home_module.dart';

final class AppModule extends Module {
  @override
  List<IModule> get routes => [ModuleRoute('/', module: HomeModule())];
}
