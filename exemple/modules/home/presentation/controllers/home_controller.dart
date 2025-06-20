import '../../domain/repositories/repository.dart';

final class HomeController {
  final ModugoRepository repository;

  HomeController(this.repository);

  String message() => repository.welcome();
}
