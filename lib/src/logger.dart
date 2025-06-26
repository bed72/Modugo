// coverage:ignore-file

import 'package:modugo/src/modugo.dart';

import 'package:talker_logger/talker_logger.dart';

/// A singleton logger utility used internally by Modugo to emit
/// diagnostic messages during development or debugging.
///
/// This logger is backed by the `talker_logger` package and uses
/// custom color schemes and tags for better visibility.
///
/// Logging is only enabled when [Modugo.debugLogDiagnostics] is set to `true`.
/// This ensures that logs are omitted in production environments.
///
/// Example usage:
/// ```dart
/// ModugoLogger.info('Module initialized');
/// ModugoLogger.error('Failed to resolve dependency');
/// ```
final class Logger {
  /// Internal logger instance from `talker_logger`.
  late final TalkerLogger _logger;

  /// Singleton instance of [Logger].
  static final Logger _instance = Logger._internal();

  /// Factory constructor returning the singleton instance.
  factory Logger() => _instance;

  /// Internal constructor that initializes the [TalkerLogger]
  /// with custom visual settings and log levels.
  Logger._internal() {
    _logger = TalkerLogger(
      settings: TalkerLoggerSettings(
        maxLineWidth: 172,
        enableColors: true,
        defaultTitle: 'MODUGO',
        colors: {
          LogLevel.info: AnsiPen()..blue(),
          LogLevel.error: AnsiPen()..red(),
          LogLevel.debug: AnsiPen()..green(),
          LogLevel.verbose: AnsiPen()..gray(),
          LogLevel.critical: AnsiPen()..cyan(),
          LogLevel.warning: AnsiPen()..yellow(),
        },
      ),
    );
  }

  /// Logs an error message with a red highlight.
  static void error(String message, {String tag = 'ERROR'}) =>
      _log(message, tag: tag, level: LogLevel.error);

  /// Logs a warning message with a yellow highlight.
  static void warn(String message, {String tag = 'WARNING'}) =>
      _log(message, tag: tag, level: LogLevel.warning);

  /// Logs a debug message related to module logic.
  static void module(String message, {String tag = 'MODULE'}) =>
      _log(message, tag: tag, level: LogLevel.critical);

  /// Logs a debug message related to disposal logic.
  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      _log(message, tag: tag, level: LogLevel.debug);

  /// Logs a debug message related to dependency injection.
  static void injection(String message, {String tag = 'INJECT'}) =>
      _log(message, tag: tag, level: LogLevel.debug);

  /// Logs an informational message with a blue highlight.
  static void information(String message, {String tag = 'INFORMATION'}) =>
      _log(message, tag: tag, level: LogLevel.info);

  /// Logs a debug message related to navigation logic.
  static void navigation(String message, {String tag = 'NAVIGATION'}) =>
      _log(message, tag: tag, level: LogLevel.debug);

  /// Returns the current time formatted as `HH:mm:ss`.
  static String _now() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
  }

  /// Logs a message with the given [level] and [tag], optionally prefixed with a timestamp.
  ///
  /// This method respects the [Modugo.debugLogDiagnostics] flag and will
  /// skip logging if the flag is set to `false`.
  static void _log(
    String message, {
    String tag = '',
    LogLevel level = LogLevel.info,
  }) {
    if (!Modugo.debugLogDiagnostics) return;

    final fullMessage = '[${_now()}] [$tag] $message';

    final _ = switch (level) {
      LogLevel.info => _instance._logger.info(fullMessage),
      LogLevel.debug => _instance._logger.debug(fullMessage),
      LogLevel.error => _instance._logger.error(fullMessage),
      LogLevel.warning => _instance._logger.warning(fullMessage),
      LogLevel.critical => _instance._logger.critical(fullMessage),
      _ => _instance._logger.info(fullMessage),
    };
  }
}
