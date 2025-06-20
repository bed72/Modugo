/// Holds the current global delay (in milliseconds) before disposing modules.
///
/// If `null`, [disposeMilisenconds] will return the default value of `2000ms`.
int? _disposeMilisenconds;

/// Returns the current delay (in milliseconds) before a module is disposed.
///
/// Defaults to `2000` if not explicitly set.
///
/// This value controls how long a module stays in memory after it becomes inactive.
/// Useful for preventing premature cleanup in case of quick navigation back-and-forth.
///
int get disposeMilisenconds => _disposeMilisenconds ?? 2000;

/// Sets the global delay (in milliseconds) used before disposing inactive modules.
///
/// You may want to increase this value in apps with frequent tab switching or deep navigation.
///
/// Example:
/// ```dart
/// setDisposeMiliseconds(3000); // wait 3 seconds before cleanup
/// ```
void setDisposeMiliseconds(int miliseconds) {
  _disposeMilisenconds = miliseconds;
}
