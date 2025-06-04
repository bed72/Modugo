// coverage:ignore-file

int? _disposeMilisenconds;

int get disposeMilisenconds => _disposeMilisenconds ?? 2000;

void setDisposeMiliseconds(int miliseconds) {
  _disposeMilisenconds = miliseconds;
}
